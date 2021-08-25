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
     * @dev Deposit NFT token
     * @notice Transfer deposited NFT token
     * @param _tokenId NFT LP Token ID
     */
    function deposit(uint256 _tokenId)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        if (_tokenId == 0) _tokenId = _getLastNftId(address(this));
        nftManager.safeTransferFrom(
            address(this),
            address(staker),
            _tokenId,
            ""
        );

        _eventName = "LogDeposit(uint256)";
        _eventParam = abi.encode(_tokenId);
    }

    /**
     * @dev Deposit Transfer
     * @notice Transfer deposited NFT token
     * @param _tokenId NFT LP Token ID
     * @param _to address to transfer
     */
    function transferDeposit(uint256 _tokenId, address _to)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        if (_tokenId == 0) _tokenId = _getLastNftId(address(this));
        staker.transferDeposit(_tokenId, _to);

        _eventName = "LogDepositTransfer(uint256,address)";
        _eventParam = abi.encode(_tokenId, _to);
    }

    /**
     * @dev Withdraw NFT LP token
     * @notice Withdraw NFT LP token from staking pool
     * @param _tokenId NFT LP Token ID
     * @param _to address to transfer
     */
    function withdraw(uint256 _tokenId, address _to)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        if (_tokenId == 0) _tokenId = _getLastNftId(address(this));
        staker.withdrawToken(_tokenId, _to, "");

        _eventName = "LogWithdraw(uint256,address)";
        _eventParam = abi.encode(_tokenId, _to);
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
        if (_tokenId == 0) _tokenId = _getLastNftId(address(this));
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
        if (_tokenId == 0) _tokenId = _getLastNftId(address(this));
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
        if (_tokenId == 0) _tokenId = _getLastNftId(address(this));
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
    string public constant name = "Uniswap-V3-Staker-v1";
}
