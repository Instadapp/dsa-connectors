pragma solidity ^0.7.5;
pragma abicoder v2;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {INonfungiblePositionManager, ISwapRouter} from "./interface.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev uniswap v3 NFT Position Manager & Swap Router
     */
    INonfungiblePositionManager nftManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    ISwapRouter swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    struct MintParams {
        address tokenA;
        address tokenB;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amtA;
        uint256 unitAmt;
    }

    /**
     * @dev Mint function which interact with Uniswap v3
     */
    function _mint(MintParams memory params)
        internal
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(
            params.tokenA,
            params.tokenB
        );

        uint256 _amount0 = params.amtA == uint256(-1)
            ? getTokenBal(TokenInterface(params.tokenA))
            : params.amtA;
        uint256 _amount1 = convert18ToDec(
            _tokenB.decimals(),
            wmul(params.unitAmt, convertTo18(_tokenA.decimals(), _amount0))
        );

        TransferHelper.safeApprove(
            params.tokenA,
            address(nftManager),
            _amount0
        );
        TransferHelper.safeApprove(
            params.tokenB,
            address(nftManager),
            _amount1
        );
        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams(
                params.tokenA,
                params.tokenB,
                params.fee,
                params.tickLower,
                params.tickUpper,
                _amount0,
                _amount1,
                0,
                0,
                address(this),
                block.timestamp
            );
        (tokenId, liquidity, amount0, amount1) = nftManager.mint(params);
    }

    /**
     * @dev addLiquidity function which interact with Uniswap v3
     */
    function _addLiquidity(
        uint256 _tokenId,
        uint256 _amount0Desired,
        uint256 _amount1Desired
    )
        internal
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager.IncreaseLiquidityParams(
                _tokenId,
                _amount0Desired,
                _amount1Desired,
                0,
                0,
                block.timestamp
            );
        (liquidity, amount0, amount1) = nftManager.increaseLiquidity(params);
    }

    /**
     * @dev decreaseLiquidity function which interact with Uniswap v3
     */
    function _decreaseLiquidity(
        uint256 _tokenId,
        uint128 _liquidity
    ) internal returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager.DecreaseLiquidityParams(
                _tokenId,
                _liquidity,
                0,
                0,
                block.timestamp
            );
        (amount0, amount1) = nftManager.decreaseLiquidity(params);
    }

    /**
     * @dev collect function which interact with Uniswap v3
     */
    function _collect(
        uint256 _tokenId,
        uint128 _amount0Max,
        uint128 _amount1Max
    ) internal returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams(
                _tokenId,
                address(this),
                _amount0Max,
                _amount1Max
            );
        (amount0, amount1) = nftManager.collect(params);
    }

    /**
     * @dev exactInputSingle function which interact with Uniswap v3
     */
    function _exactInputSingle(
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 _amountIn
    ) internal returns (uint256 amountOut) {
        TransferHelper.safeApprove(_tokenIn, address(swapRouter), _amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams(
                _tokenIn,
                _tokenOut,
                _fee,
                address(this),
                block.timestamp,
                _amountIn,
                0,
                0
            );
        amountOut = swapRouter.exactInputSingle(params);
    }
}
