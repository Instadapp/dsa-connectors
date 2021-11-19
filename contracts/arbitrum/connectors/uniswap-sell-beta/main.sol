pragma solidity ^0.7.6;
pragma abicoder v2;

import "./helpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract uniswapSellBeta is Helpers {
    using SafeERC20 for IERC20;

    function sell(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public payable returns (uint256 amountOut) {
        IERC20(tokenIn).safeApprove(address(router), amountIn);
        amountOut = swapSingleInput(
            getParams(
                tokenIn,
                tokenOut,
                address(this),
                fee,
                amountIn,
                amountOutMinimum,
                tokenOut > tokenIn
            )
        );
    }
}

contract ConnectV2UniswapSellBeta is uniswapSellBeta {
    string public constant name = "Uniswap-Sell-Beta";
}
