pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Uniswap v3.
 * @dev Decentralized Exchange.
 */

import {TokenInterface} from "../../../common/interfaces.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract UniswapResolver is Helpers, Events {
    using SafeERC20 for IERC20;

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 deadline,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) 
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        address poolAddr = getPoolAddress(tokenIn, tokenOut, fee);
        uint256 maxPrice = 0;
        uint pathIndex = 0;

        for (uint i = 0; i < COMMON_ADDRESSES.length; i++) {
            uint256 price1 = getPrice(tokenIn, COMMON_ADDRESSES[i], fee);
            uint256 price2 = getPrice(COMMON_ADDRESSES[i], tokenOut, fee);
            uint256 price = (price1 + price2) / 2;

            if (maxPrice < price) {
                maxPrice = price;
                pathIndex = i;
            }
        }

        if (poolAddr != address(0)) {
            uint256 price = getPrice(tokenIn, tokenOut, fee);

            if (maxPrice < price) {
                maxPrice = price;
            }
        }

        IERC20(tokenIn).safeApprove(address(swapRouter), amountIn);
        uint256 amountOut1 = swapSingleInput(
            getParams(
                tokenIn,
                COMMON_ADDRESSES[pathIndex],
                recipient,
                fee,
                amountIn,
                amountOutMinimum
            )
        );
        uint256 amountOut = swapSingleInput(
            getParams(
                COMMON_ADDRESSES[pathIndex],
                tokenOut,
                recipient,
                fee,
                amountOut1,
                amountOutMinimum
            )
        );

        _eventName = "LogSwapExactTokensForTokens(uint256)";
        _eventParam = abi.encode(amountOut);
    }
}

contract ConnectV2UniswapV3AutoRouter is UniswapResolver {
    string public constant name = "UniswapV3-Auto-Router-v1";
}
