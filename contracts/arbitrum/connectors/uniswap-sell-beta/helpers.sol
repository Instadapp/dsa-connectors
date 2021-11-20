pragma solidity ^0.7.6;
pragma abicoder v2;

import "hardhat/console.sol";
import {UniswapV3Pool, ISwapRouter} from "./interface.sol";
import {SqrtPriceMath} from "./libraries/SqrtPriceMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract Helpers {
    using SafeERC20 for IERC20;

    ISwapRouter internal constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    function getPoolAddress(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (address pool) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return
            computeAddress(
                0x1F98431c8aD98523631AE4a59f267346ea31F984,
                PoolKey({token0: tokenA, token1: tokenB, fee: fee})
            );
    }

    function computeAddress(address factory, PoolKey memory key)
        internal
        pure
        returns (address pool)
    {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encode(key.token0, key.token1, key.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    function getPriceLimit(
        uint256 amountIn,
        bool zeroForOne,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (uint160) {
        UniswapV3Pool state = UniswapV3Pool(
            getPoolAddress(tokenA, tokenB, fee)
        );

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
    ) internal view returns (ISwapRouter.ExactInputSingleParams memory params) {
        params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: recipient,
            deadline: block.timestamp + 1,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: getPriceLimit(
                amountIn,
                zeroForOne,
                tokenIn,
                tokenOut,
                fee
            )
        });
    }

    function SwapTokens(
        address tokenIn,
        address tokenOut,
        bool zeroForOne
    ) internal pure returns (address, address) {
        if (!zeroForOne) return (tokenOut, tokenIn);
        else return (tokenIn, tokenOut);
    }

    function swapSingleInput(ISwapRouter.ExactInputSingleParams memory params)
        internal
        returns (uint256)
    {
        return (uint256(router.exactInputSingle(params)));
    }
}
