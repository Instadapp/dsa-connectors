pragma solidity ^0.8.1;
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
