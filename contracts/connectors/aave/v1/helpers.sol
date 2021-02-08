pragma solidity ^0.7.0;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { AaveProviderInterface, AaveInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Aave Provider
    */
    AaveProviderInterface constant internal aaveProvider = AaveProviderInterface(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    /**
     * @dev Aave Referral Code
    */
    uint16 constant internal referralCode = 3228;

    /**
     * @dev Checks if collateral is enabled for an asset
     * @param aave Aave Interface
     * @param token token address of the asset.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
    */
    function getIsColl(AaveInterface aave, address token) internal view returns (bool isCol) {
        (, , , , , , , , , isCol) = aave.getUserReserveData(token, address(this));
    }

    /**
     * @dev Get total collateral balance for an asset
     * @param aave Aave Interface
     * @param token token address of the collateral.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
    */
    function getCollateralBalance(AaveInterface aave, address token) internal view returns (uint bal) {
        (bal, , , , , , , , , ) = aave.getUserReserveData(token, address(this));
    }

    /**
     * @dev Get total debt balance & fee for an asset
     * @param aave Aave Interface
     * @param token token address of the debt.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
    */
    function getPaybackBalance(AaveInterface aave, address token) internal view returns (uint bal, uint fee) {
        (, bal, , , , , fee, , , ) = aave.getUserReserveData(token, address(this));
    }
}
