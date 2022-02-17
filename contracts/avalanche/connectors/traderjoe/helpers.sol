pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { JoetrollerInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev TraderJoe Comptroller
     */
    JoetrollerInterface internal constant troller = JoetrollerInterface(0xdc13687554205E5b89Ac783db14bb5bba4A1eDaC);

    
    /**
     * @dev enter traderjoe market
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
