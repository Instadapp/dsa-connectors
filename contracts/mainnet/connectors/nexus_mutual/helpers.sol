pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {IGateway} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    IGateway internal constant gateway =
        IGateway(0x089Ab1536D032F54DFbC194Ba47529a4351af1B5);
}
