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
