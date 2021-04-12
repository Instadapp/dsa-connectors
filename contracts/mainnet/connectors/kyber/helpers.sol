pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { KyberInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Kyber Interface
     */
    KyberInterface internal constant kyber = KyberInterface(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);

    address internal constant referalAddr = 0x7284a8451d9a0e7Dc62B3a71C0593eA2eC5c5638;
}