//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface, AccountInterface } from "../../common/interfaces.sol";
import { SparkInterface, SparkPoolProviderInterface, SparkDataProviderInterface } from "./interface.sol";
import "./events.sol";
import "./interface.sol";

abstract contract Helper is DSMath, Basic {
	/**
	 * @dev Spark referal code
	 */
	uint16 internal constant referalCode = 0;

	/**
	 * @dev Spark Lending Pool Provider
	 */
	SparkPoolProviderInterface internal constant sparkProvider =
		SparkPoolProviderInterface(0x02C3eA4e34C0cBd694D2adFa2c690EECbC1793eE);

	/**
	 * @dev Spark Protocol Data Provider
	 */
	SparkDataProviderInterface internal constant sparkData =
		SparkDataProviderInterface(0xFc21d6d146E6086B8359705C8b28512a983db0cb);

	function getIsColl(address token, address user)
		internal
		view
		returns (bool isCol)
	{
		(, , , , , , , , isCol) = sparkData.getUserReserveData(token, user);
	}

	struct ImportData {
		address[] _supplyTokens;
		address[] _borrowTokens;
		STokenInterface[] sTokens;
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

contract SparkHelpers is Helper {
	function getBorrowAmount(address _token, address userAccount)
		internal
		view
		returns (uint256 stableBorrow, uint256 variableBorrow)
	{
		(
			,
			address stableDebtTokenAddress,
			address variableDebtTokenAddress
		) = sparkData.getReserveTokensAddresses(_token);

		stableBorrow = STokenInterface(stableDebtTokenAddress).balanceOf(
			userAccount
		);
		variableBorrow = STokenInterface(variableDebtTokenAddress).balanceOf(
			userAccount
		);
	}

	function getBorrowAmounts(
		address userAccount,
		SparkInterface spark,
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
					TokenInterface(_token).approve(address(spark), _amt);
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
		data.sTokens = new STokenInterface[](inputData.supplyTokens.length);

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
			(address _sToken, , ) = sparkData.getReserveTokensAddresses(_token);
			data._supplyTokens[i] = _token;
			data.sTokens[i] = STokenInterface(_sToken);
			data.supplyAmts[i] = data.sTokens[i].balanceOf(userAccount);
		}

		return data;
	}

	function _paybackBehalfOne(
		SparkInterface spark,
		address token,
		uint256 amt,
		uint256 rateMode,
		address user
	) private {
		spark.repay(token, amt, rateMode, user);
	}

	function _PaybackStable(
		uint256 _length,
		SparkInterface spark,
		address[] memory tokens,
		uint256[] memory amts,
		address user
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_paybackBehalfOne(spark, tokens[i], amts[i], 1, user);
			}
		}
	}

	function _PaybackVariable(
		uint256 _length,
		SparkInterface spark,
		address[] memory tokens,
		uint256[] memory amts,
		address user
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_paybackBehalfOne(spark, tokens[i], amts[i], 2, user);
			}
		}
	}

	function _PermitSTokens(
		address userAccount,
		STokenInterface[] memory sTokenContracts,
		address[] memory tokens,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s,
		uint256[] memory expiry
	) internal {
		for (uint256 i = 0; i < tokens.length; i++) {
			sTokenContracts[i].permit(
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

	function _TransferStokens(
		uint256 _length,
		SparkInterface spark,
		STokenInterface[] memory stokenContracts,
		uint256[] memory amts,
		address[] memory tokens,
		address userAccount
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				uint256 _amt = amts[i];
				require(
					stokenContracts[i].transferFrom(
						userAccount,
						address(this),
						_amt
					),
					"allowance?"
				);

				if (!getIsColl(tokens[i], address(this))) {
					spark.setUserUseReserveAsCollateral(tokens[i], true);
				}
			}
		}
	}

	function _TransferStokensWithCollateral(
		uint256 _length,
		SparkInterface spark,
		STokenInterface[] memory stokenContracts,
		uint256[] memory amts,
		address[] memory tokens,
		bool[] memory colEnable,
		address userAccount
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				uint256 _amt = amts[i];
				require(
					stokenContracts[i].transferFrom(
						userAccount,
						address(this),
						_amt
					),
					"allowance?"
				);

				if (!getIsColl(tokens[i], address(this))) {
					spark.setUserUseReserveAsCollateral(tokens[i], colEnable[i]);
				}
			}
		}
	}

	function _BorrowVariable(
		uint256 _length,
		SparkInterface spark,
		address[] memory tokens,
		uint256[] memory amts
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_borrowOne(spark, tokens[i], amts[i], 2);
			}
		}
	}

	function _BorrowStable(
		uint256 _length,
		SparkInterface spark,
		address[] memory tokens,
		uint256[] memory amts
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_borrowOne(spark, tokens[i], amts[i], 1);
			}
		}
	}

	function _borrowOne(
		SparkInterface spark,
		address token,
		uint256 amt,
		uint256 rateMode
	) private {
		spark.borrow(token, amt, rateMode, referalCode, address(this));
	}
}
