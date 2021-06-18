pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";


abstract contract Helpers  {
    TokenInterface constant internal wethContract = TokenInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
}
