//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
    event LogDepositLpStake(
        address indexed lptoken,
        uint256 indexed pid,
        uint256 stakedAmount,
        uint256 getId,
        uint256 setId
    );
 
    event LogWithdrawLpStake(
        address indexed lptoken,
        uint256 indexed pid,
        uint256 withdrawAmount,
        uint256 getId,
        uint256 setId
    );

    event LogWithdrawLpAndClaim(
        address indexed lptoken,
        uint256 indexed pid,
        uint256 withdrawAmount,
        uint256 rewardAmount,
        uint256 getId,
        uint256 setId
    );

    event LogClaimLpReward(
        address indexed lptoken,
        uint256 indexed pid,
        uint256 rewardAmount
    );

    event LogEmergencyWithdrawLpStake(
        address indexed lptoken,
        uint256 indexed pid,
        uint256 withdrawAmount
    );

    event LogDepositPNGStake(
        address indexed stakingContract,
        uint256 stakedAmount,
        uint256 getId,
        uint256 setId
    );

    event LogWithdrawPNGStake(
        address indexed stakingContract,
        uint256 withdrawAmount,
        uint256 getId,
        uint256 setId
    );

    event LogExitPNGStake(
        address indexed stakingContract,
        uint256 exitAmount,
        uint256 rewardAmount,
        address indexed rewardToken
    );

    event LogClaimPNGStakeReward(
        address indexed stakingContract,
        uint256 rewardAmount,
        address indexed rewardToken
    );
}