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
    INonfungiblePositionManager constant nftManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    ISwapRouter constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amt1;
        uint256 unitAmt;
        uint slippage;
    }

    function getMinAmount(
        TokenInterface token,
        uint amt,
        uint slippage
    ) internal view returns(uint minAmt) {
        uint _amt18 = convertTo18(token.decimals(), amt);
        minAmt = wmul(_amt18, sub(WAD, slippage));
        minAmt = convert18ToDec(token.decimals(), minAmt);
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
        (TokenInterface _token0, TokenInterface _token1) = changeEthAddress(
            params.token0,
            params.token1
        );

        uint256 _amount1 = params.amt1 == uint256(-1)
            ? getTokenBal(TokenInterface(params.token1))
            : params.amt1;
        uint256 _amount0 = convert18ToDec(
            _token1.decimals(),
            wmul(params.unitAmt, convertTo18(_token1.decimals(), _amount1))
        );

        _token0.approve(address(nftManager), _amount0);
        _token1.approve(address(nftManager), _amount1);

        uint _minAmt0 = getMinAmount(_token0, _amount0, params.slippage);
        uint _minAmt1 = getMinAmount(_token1, _amount1, params.slippage);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams(
                params.tokenA,
                params.tokenB,
                params.fee,
                params.tickLower,
                params.tickUpper,
                _amount0,
                _amount1,
                _minAmt0,
                _minAmt1,
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
        uint256 _amount1Desired,
        uint256 _amount0Min,
        uint256 _amount1Min,
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
                _amount0Min,
                _amount1Min,
                block.timestamp
            );
        (liquidity, amount0, amount1) = nftManager.increaseLiquidity(params);
    }

    /**
     * @dev decreaseLiquidity function which interact with Uniswap v3
     */
    function _decreaseLiquidity(
        uint256 _tokenId,
        uint128 _liquidity,
        uint256 _amount0Min,
        uint256 _amount1Min,
    ) internal returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager.DecreaseLiquidityParams(
                _tokenId,
                _liquidity,
                _amount0Min,
                _amount0Min,
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
