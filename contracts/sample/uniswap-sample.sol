pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/SqrtPriceMath.sol";

interface UniswapV3Pool {
    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint8 feeProtocol;
        bool unlocked;
    }

    function liquidity() external view returns (uint128);

    function slot0() external view returns (Slot0);
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

contract uniswapSample {
    ISwapRouter router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    UniswapV3Pool state =
        UniswapV3Pool(0xCEda10b4d3bdE429DdA3A6daB87b38360313CBdB);
    uint24 public constant poolFee = 3000;

    function computeAddress(address factory_, PoolKey memory key_)
        internal
        pure
        returns (address pool_)
    {
        require(key_.token0 < key_.token1);
        pool_ = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory_,
                            keccak256(
                                abi.encode(key_.token0, key_.token1, key_.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    function getPriceLimit(
        ISwapRouter.ExactInputSingleParams params,
        bool zeroForOne
    ) public returns (uint160) {
        return (
            getNextSqrtPriceFromInput(
                state.slot0().sqrtPriceX96,
                state.liquidity(),
                params.amountIn,
                zeroForOne
            )
        );
    }

    function sell(ISwapRouter.ExactInputSingleParams params, bool zeroForOne) {
        TransferHelper.safeTransferFrom(
            params.tokenIn,
            msg.sender,
            address(this),
            params.amountIn
        );

        TransferHelper.safeApprove(
            params.tokenIn,
            address(swapRouter),
            params.amountIn
        );

        ISwapRouter.ExactInputSingleParams memory params1 = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: params.tokenIn
                tokenOut: params.tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 1,
                amountIn: params.amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: getPriceLimit(params, true)
            });

        amountOut = swapRouter.exactInputSingle(params1);
        return (amountOut);
    }
}
