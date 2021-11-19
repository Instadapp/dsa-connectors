pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interface.sol";
import {SqrtPriceMath} from "./libraries/SqrtPriceMath.sol";
import "./libraries/TransferHelper.sol";

abstract contract Helpers is ISwapRouter {
    ISwapRouter router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    UniswapV3Pool state =
        UniswapV3Pool(0xCEda10b4d3bdE429DdA3A6daB87b38360313CBdB);

    uint24 public constant poolFee = 3000;

    function getPriceLimit(
        ISwapRouter.ExactInputSingleParams memory params,
        bool zeroForOne
    ) public returns (uint160) {
        return (
            SqrtPriceMath.getNextSqrtPriceFromInput(
                state.slot0().sqrtPriceX96,
                state.liquidity(),
                params.amountIn,
                zeroForOne
            )
        );
    }

    function approveTransfer(
        ISwapRouter.ExactInputSingleParams memory params,
        address sender,
        address recipient
    ) public {
        TransferHelper.safeTransferFrom(
            params.tokenIn,
            sender,
            recipient,
            params.amountIn
        );

        TransferHelper.safeApprove(
            params.tokenIn,
            address(router),
            params.amountIn
        );
    }

    function getSingleInput(ISwapRouter.ExactInputSingleParams memory params)
        public
        returns (uint256)
    {
        return (uint256(router.exactInputSingle(params)));
    }
}
