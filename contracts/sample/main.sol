pragma solidity ^0.7.6;
pragma abicoder v2;

import "./helpers.sol";
import "./interface.sol";

abstract contract uniswapSample is Helpers {
    function sell(
        ISwapRouter.ExactInputSingleParams memory params,
        bool zeroForOne
    ) public returns (uint256 amountOut) {
        approveTransfer(params, msg.sender, address(this));

        ISwapRouter.ExactInputSingleParams memory params1 = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 1,
                amountIn: params.amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: getPriceLimit(params, true)
            });

        amountOut = getSingleInput(params1);
    }
}

abstract contract UniswapArbitrum is uniswapSample {
    string public constant name = "UniswapSample-v1";
}
