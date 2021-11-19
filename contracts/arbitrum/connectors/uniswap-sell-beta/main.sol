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
        approveTransfer(tokenIn, msg.sender, address(this), msg.value);
        amountOut = swapSingleInput(
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

contract UniswapSellBetaArbitrum is uniswapSellBeta {
    string public constant name = "UniswapSellBeta";
}
