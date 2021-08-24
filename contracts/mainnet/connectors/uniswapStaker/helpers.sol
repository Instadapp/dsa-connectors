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
    IUniswapV3Staker constant staker =
        IUniswapV3Staker(0x1f98407aaB862CdDeF78Ed252D6f557aA5b0f00d);

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

    function getPoolAddress(uint256 _tokenId)
        internal
        view
        returns (address pool)
    {
        (bool success, bytes memory data) = address(nftManager).staticcall(
            abi.encodeWithSelector(nftManager.positions.selector, _tokenId)
        );
        require(success, "fetching positions failed");
        {
            (, , address token0, address token1, uint24 fee, , , ) = abi.decode(
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

            pool = PoolAddress.computeAddress(
                nftManager.factory(),
                PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee})
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

    function _stake(
        uint256 _tokenId,
        IUniswapV3Staker.IncentiveKey memory _incentiveId
    ) internal {
        staker.stakeToken(_incentiveId, _tokenId);
    }

    function _unstake(
        IUniswapV3Staker.IncentiveKey memory _key,
        uint256 _tokenId
    ) internal {
        staker.unstakeToken(_key, _tokenId);
    }

    function _claimRewards(
        IERC20Minimal _rewardToken,
        address _to,
        uint256 _amountRequested
    ) internal returns (uint256 rewards) {
        rewards = staker.claimReward(_rewardToken, _to, _amountRequested);
    }
}
