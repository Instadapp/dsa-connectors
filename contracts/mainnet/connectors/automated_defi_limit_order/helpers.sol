pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { ComptrollerInterface, COMPInterface, CompoundMappingInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Compound Comptroller
     */
    LimitOrderInterface internal constant limitOrderContract = LimitOrderInterface(address(0)); // TODO: add Limit Order contract's address

}