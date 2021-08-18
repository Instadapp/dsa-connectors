pragma solidity ^0.7.0;

contract Events {
    event LogMint(
        uint256 indexed tokenId,
        uint256 liquidity,
        uint256 amtA,
        uint256 amtB,
        int24 lowerTick,
        int24 upperTick
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

    event Swap(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amtIn,
        uint256 amtOut
    );

    event LogBurn(uint256 tokenId);
}
