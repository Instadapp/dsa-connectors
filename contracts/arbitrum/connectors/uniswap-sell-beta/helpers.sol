pragma solidity ^0.7.6;
pragma abicoder v2;

import {UniswapV3Pool, ISwapRouter} from "./interface.sol";
import {SqrtPriceMath} from "./libraries/SqrtPriceMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract Helpers {
    using SafeERC20 for IERC20;

    ISwapRouter public constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    UniswapV3Pool public constant state =
        UniswapV3Pool(0x17c14D2c404D167802b16C450d3c99F88F2c4F4d);

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
        IERC20(tokenIn).safeTransferFrom(sender, recipient, amountIn);

        IERC20(tokenIn).safeApprove(address(router), amountIn);
    }

    function swapSingleInput(ISwapRouter.ExactInputSingleParams memory params)
        public
        returns (uint256)
    {
        return (uint256(router.exactInputSingle(params)));
    }
}
