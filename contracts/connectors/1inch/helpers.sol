pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";


abstract contract Helpers is DSMath, Basic {
    /**
     * @dev 1Inch Address
     */
    address internal constant oneInchAddr = 0x111111125434b319222CdBf8C261674aDB56F3ae;

    /**
     * @dev 1inch swap function sig
     */
    bytes4 internal constant oneInchSig = 0x90411a32;
}