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

    event swap(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amtIn,
        uint256 amtOut
    );

    event burn(uint256 tokenId);
}
