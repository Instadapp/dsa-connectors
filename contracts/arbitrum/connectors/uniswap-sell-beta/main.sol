pragma solidity ^0.7.6;
pragma abicoder v2;

import "./helpers.sol";

contract uniswapSellBeta is Helpers {
    function sell(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum,
        bool zeroForOne
    ) public payable returns (uint256 amountOut) {
        (address tokenA, address tokenB) = SwapTokens(
            tokenIn,
            tokenOut,
            zeroForOne
        );
        approveTransfer(tokenA, amountIn);
        amountOut = swapSingleInput(
            getParams(
                tokenA,
                tokenB,
                msg.sender,
                fee,
                amountIn,
                amountOutMinimum,
                zeroForOne
            )
        );
    }
}

contract UniswapSellBetaArbitrum is uniswapSellBeta {
    string public constant name = "UniswapSellBeta";
}
