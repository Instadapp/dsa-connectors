pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(uint256 tokenId);

    event LogDepositAndStake(uint256 tokenId, bytes32 incentiveId);

    event LogWithdraw(uint256 indexed tokenId);

    event LogDepositTransfer(uint256 indexed tokenId, address to);

    event LogStake(uint256 indexed tokenId, bytes32 incentiveId);

    event LogUnstake(uint256 indexed tokenId, bytes32 incentiveId);

    event LogRewardClaimed(
        address indexed rewardToken,
        uint256 amount
    );

    event LogIncentiveCreated(
        bytes32 incentiveId,
        address poolAddr,
        address refundee,
        uint256 startTime,
        uint256 endTime,
        uint256 reward
    );
}
