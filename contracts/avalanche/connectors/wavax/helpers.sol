//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";


abstract contract Helpers  {
    TokenInterface constant internal wavaxContract = TokenInterface(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
}
