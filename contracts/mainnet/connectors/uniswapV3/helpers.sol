pragma solidity ^0.7.6;
pragma abicoder v2;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import "./interface.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev uniswap v3 NFT Position Manager & Swap Router
     */
    INonfungiblePositionManager constant nftManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    ISwapRouter constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    struct MintParams {
        address tokenA;
        address tokenB;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amtA;
        uint256 amtB;
        uint256 slippage;
    }

    /**
     * @dev Get Last NFT Index
     * @param user: User address
     */
    function _getLastNftId(address user)
        internal
        view
        returns (uint256 tokenId)
    {
        uint256 len = nftManager.balanceOf(user);
        tokenId = nftManager.tokenOfOwnerByIndex(user, len - 1);
    }

    function getMinAmount(
        TokenInterface token,
        uint256 amt,
        uint256 slippage
    ) internal view returns (uint256 minAmt) {
        uint256 _amt18 = convertTo18(token.decimals(), amt);
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
            uint256 amountA,
            uint256 amountB
        )
    {
        (TokenInterface _token0, TokenInterface _token1) = changeEthAddress(
            params.tokenA,
            params.tokenB
        );

        uint256 _amount0 = params.amtA == uint256(-1)
            ? getTokenBal(TokenInterface(params.tokenA))
            : params.amtA;
        uint256 _amount1 = params.amtB == uint256(-1)
            ? getTokenBal(TokenInterface(params.tokenB))
            : params.amtB;

        convertEthToWeth(address(_token0) == wethAddr, _token0, _amount0);
        convertEthToWeth(address(_token1) == wethAddr, _token1, _amount1);

        approve(_token0, address(nftManager), _amount0);
        approve(_token1, address(nftManager), _amount1);

        uint256 _minAmt0 = getMinAmount(_token0, _amount0, params.slippage);
        uint256 _minAmt1 = getMinAmount(_token1, _amount1, params.slippage);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams(
                address(_token0),
                address(_token1),
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

        (tokenId, liquidity, amountA, amountB) = nftManager.mint(params);
    }

    function getNftTokenPairAddresses(uint256 _tokenId)
        internal
        view
        returns (address token0, address token1)
    {
        (bool success, bytes memory data) = address(nftManager).staticcall(
            abi.encodeWithSelector(nftManager.positions.selector, _tokenId)
        );
        require(success, "fetching positions failed");
        {
            (, , token0, token1, , , , ) = abi.decode(
                data,
                (
                    uint96,
                    address,
                    address,
                    address,
                    uint24,
                    int24,
                    int24,
                    uint128
                )
            );
        }
    }

    /**
     * @dev Check if token address is etherAddr and convert it to weth
     */
    function _checkETH(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1
    ) internal {
        
        bool isEth0 = _token0 == wethAddr;
        bool isEth1 = _token1 == wethAddr;
        convertEthToWeth(isEth0, TokenInterface(_token0), _amount0);
        convertEthToWeth(isEth1, TokenInterface(_token1), _amount1);
        approve(TokenInterface(_token0), address(nftManager), _amount0);
        approve(TokenInterface(_token1), address(nftManager), _amount1);
    }

    /**
     * @dev addLiquidityWrapper function wrapper of _addLiquidity
     */
    function _addLiquidityWrapper(
        uint256 tokenId,
        uint256 amountA,
        uint256 amountB,
        uint256 slippage
    )
        internal
        returns (
            uint256 liquidity,
            uint256 amtA,
            uint256 amtB
        )
    {
        (address token0, address token1) = getNftTokenPairAddresses(tokenId);

        (liquidity, amtA, amtB) = _addLiquidity(
            tokenId,
            token0,
            token1,
            amountA,
            amountB,
            slippage
        );
    }

    /**
     * @dev addLiquidity function which interact with Uniswap v3
     */
    function _addLiquidity(
        uint256 _tokenId,
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _slippage
    )
        internal
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        _checkETH(_token0, _token1, _amount0, _amount1);
        uint256 _amount0Min = getMinAmount(
            TokenInterface(_token0),
            _amount0,
            _slippage
        );
        uint256 _amount1Min = getMinAmount(
            TokenInterface(_token1),
            _amount1,
            _slippage
        );
        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager.IncreaseLiquidityParams(
                _tokenId,
                _amount0,
                _amount1,
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
        uint256 _amount1Min
    ) internal returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager.DecreaseLiquidityParams(
                _tokenId,
                _liquidity,
                _amount0Min,
                _amount1Min,
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
     * @dev Burn Function
     */
    function _burn(uint256 _tokenId) internal {
        nftManager.burn(_tokenId);
    }
}
