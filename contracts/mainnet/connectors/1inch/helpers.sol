pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";


abstract contract Helpers is DSMath, Basic {
    /**
     * @dev 1Inch Address
     */
    address internal constant oneInchAddr = 0x11111112542D85B3EF69AE05771c2dCCff4fAa26;

    /**
     * @dev 1inch swap function sig
     */
    bytes4 internal constant oneInchSwapSig = 0x7c025200;

     /**
     * @dev 1inch swap function sig
     */
    bytes4 internal constant oneInchUnoswapSig = 0x2e95b6c8;
}