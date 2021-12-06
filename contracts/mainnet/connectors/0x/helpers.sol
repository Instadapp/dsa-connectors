pragma solidity ^0.7.0;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev 0x Address
     */
    address internal constant zeroExAddr =
        0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
}
