pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";

import { IGUniRouter } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {

    IGUniRouter public constant gUniRouter = IGUniRouter(0x8CA6fa325bc32f86a12cC4964Edf1f71655007A7);
    
}
