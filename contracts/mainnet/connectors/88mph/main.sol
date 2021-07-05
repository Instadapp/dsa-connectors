pragma solidity ^0.7.0;

/**
 * @title 88mph.
 * @dev Manage 88mph to DSA.
 */

import { AccountInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract 88MPHResolver is Events, Helpers {

}

contract ConnectV288MPH is 88MPHResolver {
    string public constant name = "88MPH-v1";
}
