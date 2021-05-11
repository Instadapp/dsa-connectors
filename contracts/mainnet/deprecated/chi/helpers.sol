pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { CHIInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    CHIInterface constant internal chi = CHIInterface(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
}
