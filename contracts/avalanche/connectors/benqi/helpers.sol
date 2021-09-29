pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { ComptrollerInterface, BenqiMappingInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Benqi Comptroller
     */
    ComptrollerInterface internal constant troller = ComptrollerInterface(0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4);

    /**
     * @dev Benqi Mapping
     */
    BenqiMappingInterface internal constant qiMapping = BenqiMappingInterface(0xe7a85d0adDB972A4f0A4e57B698B37f171519e88);

    /**
     * @dev enter benqi market
     */
    function enterMarket(address qiToken) internal {
        address[] memory markets = troller.getAssetsIn(address(this));
        bool isEntered = false;
        for (uint i = 0; i < markets.length; i++) {
            if (markets[i] == qiToken) {
                isEntered = true;
            }
        }
        if (!isEntered) {
            address[] memory toEnter = new address[](1);
            toEnter[0] = qiToken;
            troller.enterMarkets(toEnter);
        }
    }
}
