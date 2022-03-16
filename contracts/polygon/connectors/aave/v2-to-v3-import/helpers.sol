pragma solidity ^0.7.0;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import "./events.sol";
import "./interfaces.sol";

abstract contract Helper is DSMath, Basic {
	/**
	 * @dev Aave referal code
	 */
	uint16 internal constant referalCode = 3228;

	/**
	 * @dev AaveV2 Lending Pool Provider
	 */
	AaveV2LendingPoolProviderInterface internal constant aaveV2Provider =
		AaveV2LendingPoolProviderInterface(
			0xd05e3E715d945B59290df0ae8eF85c1BdB684744 // v2 address
		);

	/**
	 * @dev AaveV3 Lending Pool Provider
	 */
	AaveV3PoolProviderInterface internal constant aaveV3Provider =
		AaveV3PoolProviderInterface(
			0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb // Polygon address - PoolAddressesProvider
		);

	/**
	 * @dev Aave Protocol Data Provider
	 */
	AaveV2DataProviderInterface internal constant aaveV2Data =
		AaveV2DataProviderInterface(0x7551b5D2763519d4e37e8B81929D336De671d46d); // v2 address

	function getIsColl(address token, address user)
		internal
		view
		returns (bool isCol)
	{
		(, , , , , , , , isCol) = aaveV2Data.getUserReserveData(token, user);
	}

	struct ImportData {
		address[] _supplyTokens;
		address[] _supplyTokensV3;
		address[] _borrowTokens;
		address[] _borrowTokensV3;
		ATokenV2Interface[] aTokens;
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
		address[] supplyTokensV3;
		address[] borrowTokens;
		address[] borrowTokensV3;
		bool convertStable;
		uint256[] flashLoanFees;
	}
}

contract _AaveHelper is Helper {
	function getBorrowAmountV2(address _token, address userAccount)
		internal
		view
		returns (uint256 stableBorrow, uint256 variableBorrow)
	{
		(
			,
			address stableDebtTokenAddress,
			address variableDebtTokenAddress
		) = aaveV2Data.getReserveTokensAddresses(_token);

		stableBorrow = ATokenV2Interface(stableDebtTokenAddress).balanceOf(
			userAccount
		);
		variableBorrow = ATokenV2Interface(variableDebtTokenAddress).balanceOf(
			userAccount
		);
	}

	function getBorrowAmountsV2(
		address userAccount,
		AaveV2Interface aaveV2,
		ImportInputData memory inputData,
		ImportData memory data
	) internal returns (ImportData memory) {
		if (inputData.borrowTokens.length > 0) {
			data._borrowTokens = new address[](inputData.borrowTokens.length);
			data._borrowTokensV3 = new address[](inputData.borrowTokensV3.length);
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
				address _token = inputData.borrowTokens[i] == maticAddr
					? wmaticAddr
					: inputData.borrowTokens[i];
				address _tokenV3 = inputData.borrowTokensV3[i] == maticAddr
					? wmaticAddr
					: inputData.borrowTokensV3[i];
				data._borrowTokens[i] = _token;
				data._borrowTokensV3[i] = _tokenV3;

				(
					data.stableBorrowAmts[i],
					data.variableBorrowAmts[i]
				) = getBorrowAmountV2(_token, userAccount);

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
					TokenInterface(_token).approve(address(aaveV2), _amt);
				}
			}
		}
		return data;
	}

	function getSupplyAmountsV2(
		address userAccount,
		ImportInputData memory inputData,
		ImportData memory data
	) internal view returns (ImportData memory) {
		data.supplyAmts = new uint256[](inputData.supplyTokens.length);
		data._supplyTokens = new address[](inputData.supplyTokens.length);
		data._supplyTokensV3 = new address[](inputData.supplyTokensV3.length);
		data.aTokens = new ATokenV2Interface[](inputData.supplyTokens.length);

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
			address _token = inputData.supplyTokens[i] == maticAddr
				? wmaticAddr
				: inputData.supplyTokens[i];
			address _tokenV3 = inputData.supplyTokensV3[i] == maticAddr
				? wmaticAddr
				: inputData.supplyTokensV3[i];

			(address _aToken, , ) = aaveV2Data.getReserveTokensAddresses(
				_token
			);
			data._supplyTokens[i] = _token;
			data._supplyTokensV3[i] = _tokenV3;
			data.aTokens[i] = ATokenV2Interface(_aToken);
			data.supplyAmts[i] = data.aTokens[i].balanceOf(userAccount);
		}

		return data;
	}

	function _paybackBehalfOneV2(
		AaveV2Interface aaveV2,
		address token,
		uint256 amt,
		uint256 rateMode,
		address user
	) private {
		aaveV2.repay(token, amt, rateMode, user);
	}

	function _PaybackStableV2(
		uint256 _length,
		AaveV2Interface aaveV2,
		address[] memory tokens,
		uint256[] memory amts,
		address user
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_paybackBehalfOneV2(aaveV2, tokens[i], amts[i], 1, user);
			}
		}
	}

	function _PaybackVariableV2(
		uint256 _length,
		AaveV2Interface aaveV2,
		address[] memory tokens,
		uint256[] memory amts,
		address user
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_paybackBehalfOneV2(aaveV2, tokens[i], amts[i], 2, user);
			}
		}
	}

	function _TransferAtokensV2(
		uint256 _length,
		AaveV2Interface aaveV2,
		ATokenV2Interface[] memory atokenContracts,
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
					aaveV2.setUserUseReserveAsCollateral(tokens[i], true);
				}
			}
		}
	}

	function _WithdrawTokensFromV2(
		uint256 _length,
		AaveV2Interface aaveV2,
		uint256[] memory amts,
		address[] memory tokens
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				uint256 _amt = amts[i];
				address _token = tokens[i];
				aaveV2.withdraw(_token, _amt, address(this));
			}
		}
	}

	function _depositTokensV3(
		uint256 _length,
		AaveV3Interface aaveV3,
		uint256[] memory amts,
		address[] memory tokens
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				uint256 _amt = amts[i];
				address _token = tokens[i];
				TokenInterface tokenContract = TokenInterface(_token);
				require(
					tokenContract.balanceOf(address(this)) >= _amt,
					"Insufficient funds to deposit in v3"
				);
				approve(tokenContract, address(aaveV3), _amt);
				aaveV3.supply(_token, _amt, address(this), referalCode);

				if (!getIsColl(_token, address(this))) {
					aaveV3.setUserUseReserveAsCollateral(_token, true);
				}
			}
		}
	}

	function _BorrowVariableV3(
		uint256 _length,
		AaveV3Interface aaveV3,
		address[] memory tokens,
		uint256[] memory amts
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_borrowOneV3(aaveV3, tokens[i], amts[i], 2);
			}
		}
	}

	function _BorrowStableV3(
		uint256 _length,
		AaveV3Interface aaveV3,
		address[] memory tokens,
		uint256[] memory amts
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_borrowOneV3(aaveV3, tokens[i], amts[i], 1);
			}
		}
	}

	function _borrowOneV3(
		AaveV3Interface aaveV3,
		address token,
		uint256 amt,
		uint256 rateMode
	) private {
		aaveV3.borrow(token, amt, rateMode, referalCode, address(this));
	}
}
