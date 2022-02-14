pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";

abstract contract Helpers  {
    TokenInterface constant internal wethContract = TokenInterface(0x4200000000000000000000000000000000000006);
    TokenInterface constant internal wethFixContract = TokenInterface(0xa5044f8FfA8FbDdd0781cEDe502F1C493BB6978A); 
}
