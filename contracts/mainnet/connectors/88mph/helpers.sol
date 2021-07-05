pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {IVesting} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    IVesting internal constant vesting =
        IVesting(0x8943eb8F104bCf826910e7d2f4D59edfe018e0e7);
}
