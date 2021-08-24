pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Uniswap v3.
 * @dev Decentralized Exchange.
 */

import {TokenInterface} from "../../common/interfaces.sol";
import "./interface.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

abstract contract UniswapResolver is Helpers, Events {
    /**
     * @dev Increase Liquidity
     * @notice Increase Liquidity of NFT Position
     * @param tokenId NFT LP Token ID.
     * @param amountA tokenA amounts.
     * @param amountB tokenB amounts.
     * @param slippage slippage.
     * @param getIds IDs to retrieve token amounts
     * @param setId stores the liquidity amount
     */
    function deposit(
        uint256 tokenId,
        uint256 amountA,
        uint256 amountB,
        uint256 slippage,
        uint256[] calldata getIds,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        if (tokenId == 0) tokenId = _getLastNftId(address(this));
        amountA = getUint(getIds[0], amountA);
        amountB = getUint(getIds[1], amountB);
        (
            uint256 _liquidity,
            uint256 _amtA,
            uint256 _amtB
        ) = _addLiquidityWrapper(tokenId, amountA, amountB, slippage);
        setUint(setId, _liquidity);

        _eventName = "LogDeposit(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(tokenId, _liquidity, _amtA, _amtB);
    }

    /**
     * @dev Decrease Liquidity
     * @notice Decrease Liquidity of NFT Position
     * @param tokenId NFT LP Token ID.
     * @param liquidity LP Token amount.
     * @param amountAMin Min amount of tokenA.
     * @param amountBMin Min amount of tokenB.
     * @param getId ID to retrieve LP token amounts
     * @param setIds stores the amount of output tokens
     */
    function withdraw(
        uint256 tokenId,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 getId,
        uint256[] calldata setIds
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        if (tokenId == 0) tokenId = _getLastNftId(address(this));
        uint128 _liquidity = uint128(getUint(getId, liquidity));

        (uint256 _amtA, uint256 _amtB) = _decreaseLiquidity(
            tokenId,
            _liquidity,
            amountAMin,
            amountBMin
        );

        setUint(setIds[0], _amtA);
        setUint(setIds[1], _amtB);

        _eventName = "LogWithdraw(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(tokenId, _liquidity, _amtA, _amtB);
    }

    /**
     * @dev Stake NFT LP token
     * @notice Stake NFT LP Position
     * @param _rewardToken _rewardToken address
     * @param _startTime stake start time
     * @param _endTime stake end time
     * @param _refundee refundee address
     * @param _tokenId NFT LP token id
     */
    function stake(
        address _rewardToken,
        uint256 _startTime,
        uint256 _endTime,
        address _refundee,
        uint256 _tokenId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        nftManager.safeTransferFrom(
            address(this),
            address(staker),
            _tokenId,
            ""
        );
        address poolAddr = getPoolAddress(_tokenId);

        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        IUniswapV3Staker.IncentiveKey memory _key = IUniswapV3Staker
            .IncentiveKey(
                IERC20Minimal(_rewardToken),
                pool,
                _startTime,
                _endTime,
                _refundee
            );
        _stake(_tokenId, _key);

        _eventName = "LogStake(uint256, address)";
        _eventParam = abi.encode(_tokenId, _refundee);
    }

    /**
     * @dev Unstake NFT LP token
     * @notice Unstake NFT LP Position
     * @param _rewardToken _rewardToken address
     * @param _startTime stake start time
     * @param _endTime stake end time
     * @param _refundee refundee address
     * @param _tokenId NFT LP token id
     */
    function unstake(
        address _rewardToken,
        uint256 _startTime,
        uint256 _endTime,
        address _refundee,
        uint256 _tokenId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        address poolAddr = getPoolAddress(_tokenId);

        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        IUniswapV3Staker.IncentiveKey memory _key = IUniswapV3Staker
            .IncentiveKey(
                IERC20Minimal(_rewardToken),
                pool,
                _startTime,
                _endTime,
                _refundee
            );
        _unstake(_key, _tokenId);
        _eventName = "LogUnstake(uint256,bytes32)";
        _eventParam = abi.encode(_tokenId, _key);
    }

    /**
     * @dev Claim rewards
     * @notice Claim rewards
     * @param _rewardToken _rewardToken address
     * @param _to address to receive
     * @param _amountRequested requested amount
     */
    function claimRewards(
        address _rewardToken,
        address _to,
        uint256 _amountRequested
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 rewards = _claimRewards(
            IERC20Minimal(_rewardToken),
            _to,
            _amountRequested
        );

        _eventName = "LogRewardClaimed(address,address,uint256)";
        _eventParam = abi.encode(_rewardToken, _to, rewards);
    }

    /**
     * @dev Create incentive
     * @notice Create incentive
     * @param _rewardToken _rewardToken address
     * @param _length incentive length
     * @param _refundee refundee address
     * @param _tokenId NFT LP token id
     * @param _reward reward amount
     */
    function createIncentive(
        address _rewardToken,
        uint256 _length,
        address _refundee,
        uint256 _tokenId,
        uint256 _reward
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        address poolAddr = getPoolAddress(_tokenId);

        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        uint256 _startTime = block.timestamp;
        uint256 _endTime = _startTime + _length;
        IUniswapV3Staker.IncentiveKey memory _key = IUniswapV3Staker
            .IncentiveKey(
                IERC20Minimal(_rewardToken),
                pool,
                _startTime,
                _endTime,
                _refundee
            );
        staker.createIncentive(_key, _reward);

        _eventName = "LogIncentiveCreated(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(_tokenId, _startTime, _endTime, _reward);
    }
}

contract ConnectV2UniswapV3Staker is UniswapResolver {
    string public constant name = "UniswapStaker-v1";
}
