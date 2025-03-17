//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import { AaveInterface, AavePoolProviderInterface, AaveDataProviderInterface } from "./interface.sol";
import "./events.sol";
import "./interface.sol";

abstract contract Helper is DSMath, Basic {
	/**
	 * @dev Aave referal code
	 */
	uint16 internal constant referalCode = 3228;

	/**
	 * @dev Aave Lending Pool Provider
	 */
	AavePoolProviderInterface internal constant aaveProvider =
		AavePoolProviderInterface(0xe20fCBdBfFC4Dd138cE8b2E6FBb6CB49777ad64D);

	/**
	 * @dev Aave Protocol Data Provider
	 */
	AaveDataProviderInterface internal constant aaveData =
		AaveDataProviderInterface(0xd82a47fdebB5bf5329b09441C3DaB4b5df2153Ad);

	function getIsColl(address token, address user)
		internal
		view
		returns (bool isCol)
	{
		(, , , , , , , , isCol) = aaveData.getUserReserveData(token, user);
	}

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
	}

	struct ImportInputData {
		address[] supplyTokens;
		address[] borrowTokens;
		bool convertStable;
		uint256[] flashLoanFees;
	}

	struct SignedPermits {
		uint8[] v;
		bytes32[] r;
		bytes32[] s;
		uint256[] expiry;
	}
}

contract AaveHelpers is Helper {
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
			data.variableBorrowAmtsWithFee = new uint256[](
				inputData.borrowTokens.length
			);
			data.stableBorrowAmts = new uint256[](
				inputData.borrowTokens.length
			);
			data.stableBorrowAmtsWithFee = new uint256[](
				inputData.borrowTokens.length
			);
			data.totalBorrowAmts = new uint256[](inputData.borrowTokens.length);
			data.totalBorrowAmtsWithFee = new uint256[](
				inputData.borrowTokens.length
			);
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
				) = getBorrowAmount(_token, userAccount);

				if (data.variableBorrowAmts[i] != 0) {
					data.variableBorrowAmtsWithFee[i] = add(
						data.variableBorrowAmts[i],
						inputData.flashLoanFees[i]
					);
					data.stableBorrowAmtsWithFee[i] = data.stableBorrowAmts[i];
				} else {
					data.stableBorrowAmtsWithFee[i] = add(
						data.stableBorrowAmts[i],
						inputData.flashLoanFees[i]
					);
				}

				data.totalBorrowAmts[i] = add(
					data.stableBorrowAmts[i],
					data.variableBorrowAmts[i]
				);
				data.totalBorrowAmtsWithFee[i] = add(
					data.stableBorrowAmtsWithFee[i],
					data.variableBorrowAmtsWithFee[i]
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

	function _PermitATokens(
		address userAccount,
		ATokenInterface[] memory aTokenContracts,
		address[] memory tokens,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s,
		uint256[] memory expiry
	) internal {
		for (uint256 i = 0; i < tokens.length; i++) {
			aTokenContracts[i].permit(
				userAccount,
				address(this),
				uint256(-1),
				expiry[i],
				v[i],
				r[i],
				s[i]
			);
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

	function _TransferAtokensWithCollateral(
		uint256 _length,
		AaveInterface aave,
		ATokenInterface[] memory atokenContracts,
		uint256[] memory amts,
		address[] memory tokens,
		bool[] memory colEnable,
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
					aave.setUserUseReserveAsCollateral(tokens[i], colEnable[i]);
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
}
