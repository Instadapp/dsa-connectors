pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { ComptrollerInterface, CreamMappingInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Cream Comptroller
     */
    ComptrollerInterface internal constant troller = ComptrollerInterface(0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258);

    /**
     * @dev Cream Mapping
     */
    // TODO: wait for the cream mapping contract address
    CreamMappingInterface internal constant creamMapping = CreamMappingInterface(address(0));

    /**
     * @dev enter cream market
     */
    function enterMarket(address cToken) internal {
        address[] memory markets = troller.getAssetsIn(address(this));
        bool isEntered = false;
        for (uint i = 0; i < markets.length; i++) {
            if (markets[i] == cToken) {
                isEntered = true;
            }
        }
        if (!isEntered) {
            address[] memory toEnter = new address[](1);
            toEnter[0] = cToken;
            troller.enterMarkets(toEnter);
        }
    }
}
