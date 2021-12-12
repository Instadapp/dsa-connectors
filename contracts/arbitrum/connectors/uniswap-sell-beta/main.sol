pragma solidity ^0.7.6;
pragma abicoder v2;

import "./helpers.sol";
import {Events} from "./events.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract uniswapSellBeta is Helpers, Events {
    using SafeERC20 for IERC20;

    function sell(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        IERC20(tokenIn).safeApprove(address(router), amountIn);
        uint256 amountOut = swapSingleInput(
            getParams(
                tokenIn,
                tokenOut,
                address(this),
                fee,
                amountIn,
                amountOutMinimum
            )
        );
        _eventName = "LogSell(uint24,uint256,uint256,uint256)";
        _eventParam = abi.encode(fee, amountIn, amountOut, amountOutMinimum);
    }
}

contract ConnectV2UniswapSellBeta is uniswapSellBeta {
    string public constant name = "Uniswap-Sell-Beta";
}
