pragma solidity ^0.7.0;

contract Events {
    event LogMint(
        uint256 indexed tokenId,
        uint256 liquidity,
        uint256 amtA,
        uint256 amtB,
        int24 tickLower,
        int24 tickUpper
    );

    event LogDeposit(
        uint256 indexed tokenId,
        uint256 liquidity,
        uint256 amountA,
        uint256 amountB
    );

    event LogWithdraw(
        uint256 indexed tokenId,
        uint256 liquidity,
        uint256 amountA,
        uint256 amountB
    );

    event LogCollect(
        uint256 tokenId,
        uint256 amountA,
        uint256 amountB
    );

    event LogBurnPosition(uint256 tokenId);
}
