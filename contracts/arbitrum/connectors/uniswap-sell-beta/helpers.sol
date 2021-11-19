pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interface.sol";
import {SqrtPriceMath} from "./libraries/SqrtPriceMath.sol";
import "./libraries/TransferHelper.sol";

contract Helpers is ISwapRouter {
    ISwapRouter constant public router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    UniswapV3Pool constant public state =
        UniswapV3Pool(0xCEda10b4d3bdE429DdA3A6daB87b38360313CBdB);

    function getPriceLimit(uint256 amountIn, bool zeroForOne)
        public
        returns (uint160)
    {
        return (
            SqrtPriceMath.getNextSqrtPriceFromInput(
                state.slot0().sqrtPriceX96,
                state.liquidity(),
                amountIn,
                zeroForOne
            )
        );
    }

    function getParams(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum,
        bool zeroForOne
    ) public returns (ISwapRouter.ExactInputSingleParams memory params) {
        params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: recipient,
            deadline: block.timestamp + 1,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: getPriceLimit(amountIn, zeroForOne)
        });
    }

    function approveTransfer(
        address tokenIn,
        address sender,
        address recipient,
        uint256 amountIn
    ) public {
        TransferHelper.safeTransferFrom(tokenIn, sender, recipient, amountIn);

        TransferHelper.safeApprove(tokenIn, address(router), amountIn);
    }

    function swapSingleInput(ISwapRouter.ExactInputSingleParams memory params)
        public
        returns (uint256)
    {
        return (uint256(router.exactInputSingle(params)));
    }
}
