pragma solidity ^0.7.0;

import { TokenInterface } from "../../../common/interfaces.sol";

struct SwapData {
    TokenInterface sellToken;
    TokenInterface buyToken;
    uint _sellAmt;
    uint _buyAmt;
    uint unitAmt;
    bytes callData;
}