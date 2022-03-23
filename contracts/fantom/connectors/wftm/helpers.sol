//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";


abstract contract Helpers  {
    TokenInterface constant internal wftmContract = TokenInterface(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
}
