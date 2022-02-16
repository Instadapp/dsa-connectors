pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { JoetrollerInterface, JoeTraderMappingInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Compound Comptroller
     */
    JoetrollerInterface internal constant troller = JoetrollerInterface(0xdc13687554205E5b89Ac783db14bb5bba4A1eDaC);

    /**
     * @dev Compound Mapping
     */
    JoeTraderMappingInterface internal constant compMapping = JoeTraderMappingInterface(0xe7a85d0adDB972A4f0A4e57B698B37f171519e88);

    /**
     * @dev enter compound market
     */
    function enterMarket(address jToken) internal {
        address[] memory markets = troller.getAssetsIn(address(this));
        bool isEntered = false;
        for (uint i = 0; i < markets.length; i++) {
            if (markets[i] == jToken) {
                isEntered = true;
            }
        }
        if (!isEntered) {
            address[] memory toEnter = new address[](1);
            toEnter[0] = jToken;
            troller.enterMarkets(toEnter);
        }
    }
}
