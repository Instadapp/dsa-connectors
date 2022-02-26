pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { AaveInterface, ATokenInterface, IFlashLoan } from "./interface.sol";
import { Events } from "./events.sol";

contract AaveResolver is Helpers, Events {
	struct ImportData {
		address[] _supplyTokens;
		address[] _borrowTokens;
		ATokenInterface[] aTokens;
		uint256[] supplyAmts;
		uint256[] variableBorrowAmts;
		uint256[] variableBorrowAmtsWithFee;
		uint256[] stableBorrowAmts;
		uint256[] stableBorrowAmtsWithFee;
		uint256[] totalBorrowAmts;
		uint256[] totalBorrowAmtsWithFee;
		bool convertStable;
		address userAccount;
	}

	struct ImportInputData {
		address userAccount;
		address[] supplyTokens;
		address[] borrowTokens;
		bool convertStable;
	}

	function _paybackBehalfOne(
		AaveInterface aave,
		address token,
		uint256 amt,
		uint256 rateMode,
		address user
	) private {
		aave.repay(token, amt, rateMode, user);
	}

	function _PaybackStable(
		uint256 _length,
		AaveInterface aave,
		address[] memory tokens,
		uint256[] memory amts,
		address user
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_paybackBehalfOne(aave, tokens[i], amts[i], 1, user);
			}
		}
	}

	function _PaybackVariable(
		uint256 _length,
		AaveInterface aave,
		address[] memory tokens,
		uint256[] memory amts,
		address user
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_paybackBehalfOne(aave, tokens[i], amts[i], 2, user);
			}
		}
	}

	function _TransferAtokens(
		uint256 _length,
		AaveInterface aave,
		ATokenInterface[] memory atokenContracts,
		uint256[] memory amts,
		address[] memory tokens,
		address userAccount
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				uint256 _amt = amts[i];
				require(
					atokenContracts[i].transferFrom(
						userAccount,
						address(this),
						_amt
					),
					"allowance?"
				);

				if (!getIsColl(tokens[i], address(this))) {
					aave.setUserUseReserveAsCollateral(tokens[i], true);
				}
			}
		}
	}

	function _BorrowVariable(
		uint256 _length,
		AaveInterface aave,
		address[] memory tokens,
		uint256[] memory amts
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_borrowOne(aave, tokens[i], amts[i], 2);
			}
		}
	}

	function _BorrowStable(
		uint256 _length,
		AaveInterface aave,
		address[] memory tokens,
		uint256[] memory amts
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_borrowOne(aave, tokens[i], amts[i], 1);
			}
		}
	}

	function _borrowOne(
		AaveInterface aave,
		address token,
		uint256 amt,
		uint256 rateMode
	) private {
		aave.borrow(token, amt, rateMode, referalCode, address(this));
	}

	function _includeFee(ImportData memory Data, uint256[] calldata premiums)
		internal
		returns (ImportData memory)
	{
		for (uint256 i = 0; i < Data._borrowTokens.length; i++) {
			Data.totalBorrowAmtsWithFee[i] =
				Data.totalBorrowAmts[i] +
				premiums[i];
			Data.variableBorrowAmtsWithFee[i] =
				Data.variableBorrowAmts[i] +
				premiums[i];
		}
		return Data;
	}

	function _balance(address token) internal view returns (uint256 balance) {
		balance = TokenInterface(token).balanceOf(address(this));
	}

	function _repay(
		address[] memory tokens,
		uint256[] memory amounts,
		address recepient
	) internal {
		for (uint256 i = 0; i < tokens.length; i++) {
			require(_balance(tokens[i]) >= amounts[i], "Repay failed!");
			TokenInterface(tokens[i]).transfer(recepient, amounts[i]);
		}
	}
}

contract AaveHelpers is AaveResolver {
	function getBorrowAmount(address _token, address userAccount)
		internal
		view
		returns (uint256 stableBorrow, uint256 variableBorrow)
	{
		(
			,
			address stableDebtTokenAddress,
			address variableDebtTokenAddress
		) = aaveData.getReserveTokensAddresses(_token);

		stableBorrow = ATokenInterface(stableDebtTokenAddress).balanceOf(
			userAccount
		);
		variableBorrow = ATokenInterface(variableDebtTokenAddress).balanceOf(
			userAccount
		);
	}

	function getBorrowAmounts(
		address userAccount,
		AaveInterface aave,
		ImportInputData memory inputData,
		ImportData memory data
	) internal returns (ImportData memory) {
		if (inputData.borrowTokens.length > 0) {
			data._borrowTokens = new address[](inputData.borrowTokens.length);
			data.variableBorrowAmts = new uint256[](
				inputData.borrowTokens.length
			);
			data.stableBorrowAmts = new uint256[](
				inputData.borrowTokens.length
			);
			data.totalBorrowAmts = new uint256[](inputData.borrowTokens.length);
			for (uint256 i = 0; i < inputData.borrowTokens.length; i++) {
				for (uint256 j = i; j < inputData.borrowTokens.length; j++) {
					if (j != i) {
						require(
							inputData.borrowTokens[i] !=
								inputData.borrowTokens[j],
							"token-repeated"
						);
					}
				}
			}
			for (uint256 i = 0; i < inputData.borrowTokens.length; i++) {
				address _token = inputData.borrowTokens[i] == ethAddr
					? wethAddr
					: inputData.borrowTokens[i];
				data._borrowTokens[i] = _token;

				(
					data.stableBorrowAmts[i],
					data.variableBorrowAmts[i]
				) = getBorrowAmount(_token, inputData.userAccount);

				data.totalBorrowAmts[i] = add(
					data.stableBorrowAmts[i],
					data.variableBorrowAmts[i]
				);

				if (data.totalBorrowAmts[i] > 0) {
					uint256 _amt = data.totalBorrowAmts[i];
					TokenInterface(_token).approve(address(aave), _amt);
				}
			}
		}
		return data;
	}

	function getSupplyAmounts(
		address userAccount,
		ImportInputData memory inputData,
		ImportData memory data
	) internal view returns (ImportData memory) {
		data.supplyAmts = new uint256[](inputData.supplyTokens.length);
		data._supplyTokens = new address[](inputData.supplyTokens.length);
		data.aTokens = new ATokenInterface[](inputData.supplyTokens.length);

		for (uint256 i = 0; i < inputData.supplyTokens.length; i++) {
			for (uint256 j = i; j < inputData.supplyTokens.length; j++) {
				if (j != i) {
					require(
						inputData.supplyTokens[i] != inputData.supplyTokens[j],
						"token-repeated"
					);
				}
			}
		}
		for (uint256 i = 0; i < inputData.supplyTokens.length; i++) {
			address _token = inputData.supplyTokens[i] == ethAddr
				? wethAddr
				: inputData.supplyTokens[i];
			(address _aToken, , ) = aaveData.getReserveTokensAddresses(_token);
			data._supplyTokens[i] = _token;
			data.aTokens[i] = ATokenInterface(_aToken);
			data.supplyAmts[i] = data.aTokens[i].balanceOf(userAccount);
		}

		return data;
	}

	function flashBorrow(
		address[] memory _tokens,
		uint256[] memory _amts,
		uint256 _route,
		bytes memory _data
	) public {
		bytes memory instaData;
		IFlashLoan flashLoan = IFlashLoan(flashloanAddr);
		flashLoan.flashLoan(_tokens, _amts, _route, _data, instaData);
	}

	function executeOperation(
		address[] calldata tokens,
		uint256[] calldata amounts,
		uint256[] calldata premiums,
		address initiator,
		bytes calldata params
	) external returns (bool) {
		ImportData memory data;
		(data) = abi.decode(params, (ImportData));

		// 1. payback borrowed amount;
		AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());
		_PaybackStable(
			data._borrowTokens.length,
			aave,
			data._borrowTokens,
			data.stableBorrowAmts,
			data.userAccount
		);
		_PaybackVariable(
			data._borrowTokens.length,
			aave,
			data._borrowTokens,
			data.variableBorrowAmts,
			data.userAccount
		);

		// 2. transfer atokens to this address;
		_TransferAtokens(
			data._supplyTokens.length,
			aave,
			data.aTokens,
			data.supplyAmts,
			data._supplyTokens,
			data.userAccount
		);
		// 3. take debt including flashloan fee;
		data = _includeFee(data, premiums);

		if (data.convertStable) {
			_BorrowVariable(
				data._borrowTokens.length,
				aave,
				data._borrowTokens,
				data.totalBorrowAmtsWithFee
			);
		} else {
			_BorrowStable(
				data._borrowTokens.length,
				aave,
				data._borrowTokens,
				data.stableBorrowAmts
			);
			_BorrowVariable(
				data._borrowTokens.length,
				aave,
				data._borrowTokens,
				data.variableBorrowAmtsWithFee
			);
		}
		// 4. repay flashloan with the borrowed assets
		_repay(data._borrowTokens, data.totalBorrowAmtsWithFee, flashloanAddr);
	}
}

contract AaveV3ImportResolver is AaveHelpers {
	function _importAave(address userAccount, ImportInputData memory inputData)
		internal
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(
			AccountInterface(address(this)).isAuth(userAccount),
			"user-account-not-auth"
		);

		require(inputData.supplyTokens.length > 0, "0-length-not-allowed");

		ImportData memory data;

		AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

		data = getBorrowAmounts(userAccount, aave, inputData, data);
		data = getSupplyAmounts(userAccount, inputData, data);
		data.convertStable = inputData.convertStable;

		bytes memory _callData = abi.encode(data);

		flashBorrow(data._borrowTokens, data.totalBorrowAmts, 5, _callData);

		_eventName = "LogAaveV2Import(address,bool,address[],address[],uint256[],uint256[],uint256[])";
		_eventParam = abi.encode(
			userAccount,
			inputData.convertStable,
			inputData.supplyTokens,
			inputData.borrowTokens,
			data.supplyAmts,
			data.stableBorrowAmts,
			data.variableBorrowAmts
		);
	}

	function importAave(address userAccount, ImportInputData memory inputData)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importAave(userAccount, inputData);
	}

	function migrateAave(ImportInputData memory inputData)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importAave(msg.sender, inputData);
	}
}

contract ConnectV2AaveV3Import is AaveV3ImportResolver {
	string public constant name = "Aave-v3-Import-v2";
}
