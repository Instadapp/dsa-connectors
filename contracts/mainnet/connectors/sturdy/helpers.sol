//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { SturdyAddressesProviderInterface, SturdyDataProviderInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    
    /**
     * @dev Sturdy Address Provider
    */
    SturdyAddressesProviderInterface constant internal sturdyAddressesProvider = SturdyAddressesProviderInterface(0xb7499a92fc36e9053a4324aFfae59d333635D9c3);

    /**
     * @dev Sturdy Protocol Data Provider
    */
    SturdyDataProviderInterface constant internal sturdyData = SturdyDataProviderInterface(0x960993Cb6bA0E8244007a57544A55bDdb52db97e);

    /**
     * @dev Sturdy Lido Vault
    */
    address constant internal sturdyLidoVault = 0x01c05337354aae5345d27d2A4A70B56a17aF2b4a;

    /**
     * @dev Sturdy Referral Code
    */
    uint16 constant internal referralCode = 3333;

    /**
     * @dev Return Wrapped ETH address
    */
    address constant internal stEthAddr = 0xDFe66B14D37C77F4E9b180cEb433d1b164f0281D;

    /**
     * @dev Get total debt balance & fee for an asset
     * @param token token address of the debt.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param rateMode Borrow rate mode (Stable = 1, Variable = 2)
    */
    function getRepayBalance(address token, uint rateMode) internal view returns (uint) {
        (, uint stableDebt, uint variableDebt, , , , , , ) = sturdyData.getUserReserveData(token, address(this));
        return rateMode == 1 ? stableDebt : variableDebt;
    }

    /**
	 * @dev Get OnBehalfOf user's total debt balance & fee for an asset
	 * @param token token address of the debt.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param rateMode Borrow rate mode (Stable = 1, Variable = 2)
	 */
	function getOnBehalfOfRepayBalance(address token, uint256 rateMode, address onBehalfOf)
		internal
		view
		returns (uint256)
	{
		(, uint256 stableDebt, uint256 variableDebt, , , , , , ) = sturdyData
			.getUserReserveData(token, onBehalfOf);
		return rateMode == 1 ? stableDebt : variableDebt;
	}
}
