pragma solidity ^0.7.0;

contract Events {
    event LogNewPositionMint(
        uint256 indexed tokenId,
        uint256 amtA,
        uint256 amtB,
        uint256 liquidity
    );

    event LogAddLiquidity(
        uint256 indexed tokenId,
        uint256 amtA,
        uint256 amtB,
        uint256 liquidity
    );

    event LogDecreaseLiquidity(
        uint256 indexed tokenId,
        uint256 liquidity,
        uint256 amtA,
        uint256 amtB
    );

    event Swap(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amtIn,
        uint256 amtOut
    );

    event BurnPosition(uint256 tokenId);
}
