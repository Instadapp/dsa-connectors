pragma solidity ^0.7.6;
pragma abicoder v2;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
}
