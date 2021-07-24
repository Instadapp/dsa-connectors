pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { Basic } from "../../common/basic.sol";

abstract contract Helpers is Basic {
    /**
     * @dev Compound Comptroller
     */
    LimitOrderInterface internal constant limitOrderContract = LimitOrderInterface(address(0)); // TODO: add Limit Order contract's address

}