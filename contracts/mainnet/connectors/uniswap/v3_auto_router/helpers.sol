pragma solidity ^0.7.6;
pragma abicoder v2;

import {TokenInterface} from "../../../common/interfaces.sol";
import {DSMath} from "../../../common/math.sol";
import {Basic} from "../../../common/basic.sol";
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
    ISwapRouter internal constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    
    address constant COMMON_ADDRESSES = [
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
        0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48, // USDC
        0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
        0x6b175474e89094c44da98b954eedeac495271d0f, // DAI
    ]

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

    function getPrice(address tokenIn, address tokenOut, uint24 fee)
        external
        view
        returns (uint256 price)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(tokenIn, tokenOut, fee);
        (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
        return uint(sqrtPriceX96).mul(uint(sqrtPriceX96)).mul(1e18) >> (96 * 2);
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
    function getParams(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum
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
                tokenIn < tokenOut,
                tokenIn,
                tokenOut,
                fee
            )
        });
    }

    function swapSingleInput(ISwapRouter.ExactInputSingleParams memory params)
        internal
        returns (uint256)
    {
        return (uint256(swapRouter.exactInputSingle(params)));
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

    function sortTokenAddress(address _token0, address _token1)
        internal
        view
        returns (address token0, address token1)
    {
        if (_token0 > _token1) {
            (token0, token1) = (_token1, _token0);
        } else {
            (token0, token1) = (_token0, _token1);
        }
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

        {
            (address token0, ) = sortTokenAddress(
                address(_token0),
                address(_token1)
            );

            if (token0 != address(_token0)) {
                (_token0, _token1) = (_token1, _token0);
                (_amount0, _amount1) = (_amount1, _amount0);
            }
        }
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