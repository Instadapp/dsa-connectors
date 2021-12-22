pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        uint256 indexed tokenId,
        uint256 liquidity,
        uint256 amtA,
        uint256 amtB,
        int24 tickLower,
        int24 tickUpper
    );

    event LogWithdraw(
        uint256 indexed tokenId,
        uint256 liquidity,
        uint256 amountA,
        uint256 amountB
    );
}