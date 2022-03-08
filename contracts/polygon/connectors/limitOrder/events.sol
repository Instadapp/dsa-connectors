pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

contract Events {
    event LogCreate(
        uint256 indexed tokenId,
        uint256 liquidity,
        uint256 amount,
        int24 tickLower,
        int24 tickUpper
    );

    event LogWithdrawMid(
        uint256 indexed tokenId,
        uint256 liquidity,
        uint256 amountA,
        uint256 amountB
    );

    event LogWithdrawFull(
        uint256 indexed tokenId,
        uint256 liquidity
    );
}
