pragma solidity ^0.7.6;
pragma abicoder v2;

import "./helpers.sol";

abstract contract uniswapSellBeta is Helpers {
    function sell(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum,
        bool zeroForOne
    ) public returns (uint256 amountOut) {
        approveTransfer(tokenIn, msg.sender, address(this), amountIn);
        amountOut = getSingleInput(
            getParams(
                tokenIn,
                tokenOut,
                msg.sender,
                fee,
                amountIn,
                amountOutMinimum,
                zeroForOne
            )
        );
    }
}

abstract contract UniswapSellBetaArbitrum is uniswapSellBeta {
    string public constant name = "UniswapSample-v1";
}
