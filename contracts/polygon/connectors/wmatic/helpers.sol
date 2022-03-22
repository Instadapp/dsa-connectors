//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";


abstract contract Helpers  {
    TokenInterface constant internal wmaticContract = TokenInterface(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
}
