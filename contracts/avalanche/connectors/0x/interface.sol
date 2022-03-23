//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {TokenInterface} from "../../common/interfaces.sol";

struct ZeroExData {
    TokenInterface sellToken;
    TokenInterface buyToken;
    uint256 _sellAmt;
    uint256 _buyAmt;
    uint256 unitAmt;
    bytes callData;
}
