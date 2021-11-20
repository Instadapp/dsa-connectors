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
        uint256 amountOutMinimum,
        bool zeroForOne
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        (address token0, address token1) = SwapTokens(
            tokenIn,
            tokenOut,
            zeroForOne
        );
        IERC20(token0).safeApprove(address(router), amountIn);
        uint256 amountOut = swapSingleInput(
            getParams(
                token0,
                token1,
                address(this),
                fee,
                amountIn,
                amountOutMinimum,
                zeroForOne
            )
        );
        _eventName = "LogSell(uint24,uint256,uint256,uint256,bool)";
        _eventParam = abi.encode(
            fee,
            amountIn,
            amountOut,
            amountOutMinimum,
            zeroForOne
        );
    }
}

contract ConnectV2UniswapSellBeta is uniswapSellBeta {
    string public constant name = "Uniswap-Sell-Beta";
}
