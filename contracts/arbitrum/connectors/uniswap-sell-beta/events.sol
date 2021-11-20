pragma solidity ^0.7.0;

contract Events {
    event LogSell(
        uint24 fee,
        uint256 amountIn,
        uint256 amountOut,
        uint256 amountOutMinimum,
        bool zeroForOne
    );
}
