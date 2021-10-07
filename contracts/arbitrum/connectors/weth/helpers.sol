pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";


abstract contract Helpers  {
    TokenInterface constant internal wethContract = TokenInterface(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
}
