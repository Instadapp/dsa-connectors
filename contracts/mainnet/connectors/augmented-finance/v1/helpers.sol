// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { AugmentedFinanceLendingPoolProviderInterface, AugmentedFinanceDataProviderInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Augmented Finance Market Access Controller
     */
    AugmentedFinanceLendingPoolProviderInterface
        internal constant augmentedProvider =
        AugmentedFinanceLendingPoolProviderInterface(
            0xc6f769A0c46cFFa57d91E87ED3Bc0cd338Ce6361
        );

    /**
     * @dev Augmented Finance Protocol Data Provider
     */
    AugmentedFinanceDataProviderInterface internal constant augmentedData =
        AugmentedFinanceDataProviderInterface(
            0xd25C4a0b0c088DC8d501e4292cF28da6829023c0
        );

    /**
     * @dev Checks if collateral is enabled for an asset
     * @param token token address of the asset (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function checkIsCollateral(address token)
        internal
        view
        returns (bool isCollateral)
    {
        (, , , , , , , , isCollateral) = augmentedData.getUserReserveData(
            token,
            address(this)
        );
    }

    /**
     * @dev Get total debt balance & fee for an asset
     * @param token token address of the debt (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param rateMode Borrow rate mode (Stable = 1, Variable = 2)
     */
    function getPaybackBalance(address token, uint256 rateMode)
        internal
        view
        returns (uint256)
    {
        (, uint256 stableDebt, uint256 variableDebt, , , , , , ) = augmentedData
            .getUserReserveData(token, address(this));

        return rateMode == 1 ? stableDebt : variableDebt;
    }

    /**
     * @dev Get total collateral balance for an asset
     * @param token token address of the collateral (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function getCollateralBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        (balance, , , , , , , , ) = augmentedData.getUserReserveData(
            token,
            address(this)
        );
    }
}
