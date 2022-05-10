//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { AaveLendingPoolProviderInterface, AaveDataProviderInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	/**
	 * @dev Aave Lending Pool Provider
	 */
	AaveLendingPoolProviderInterface internal constant aaveProvider =
		AaveLendingPoolProviderInterface(
			0xb6A86025F0FE1862B372cb0ca18CE3EDe02A318f
		);

	/**
	 * @dev Aave Protocol Data Provider
	 */
	AaveDataProviderInterface internal constant aaveData =
		AaveDataProviderInterface(0x65285E9dfab318f57051ab2b139ccCf232945451);

	/**
	 * @dev Aave Referral Code
	 */
	uint16 internal constant referralCode = 3228;

	/**
	 * @dev Checks if collateral is enabled for an asset
	 * @param token token address of the asset.(For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 */
	function getIsColl(address token) internal view returns (bool isCol) {
		(, , , , , , , , isCol) = aaveData.getUserReserveData(
			token,
			address(this)
		);
	}

	/**
	 * @dev Get total debt balance & fee for an asset
	 * @param token token address of the debt.(For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param rateMode Borrow rate mode (Stable = 1, Variable = 2)
	 */
	function getPaybackBalance(address token, uint256 rateMode)
		internal
		view
		returns (uint256)
	{
		(, uint256 stableDebt, uint256 variableDebt, , , , , , ) = aaveData
			.getUserReserveData(token, address(this));
		return rateMode == 1 ? stableDebt : variableDebt;
	}

	/**
	 * @dev Get OnBehalfOf user's total debt balance & fee for an asset
	 * @param token token address of the debt.(For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param rateMode Borrow rate mode (Stable = 1, Variable = 2)
	 */
	function getOnBehalfOfPaybackBalance(
		address token,
		uint256 rateMode,
		address onBehalfOf
	) internal view returns (uint256) {
		(, uint256 stableDebt, uint256 variableDebt, , , , , , ) = aaveData
			.getUserReserveData(token, onBehalfOf);
		return rateMode == 1 ? stableDebt : variableDebt;
	}

	/**
	 * @dev Get total collateral balance for an asset
	 * @param token token address of the collateral.(For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 */
	function getCollateralBalance(address token)
		internal
		view
		returns (uint256 bal)
	{
		(bal, , , , , , , , ) = aaveData.getUserReserveData(
			token,
			address(this)
		);
	}
}
