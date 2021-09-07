pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(uint256 tokenId);

    event LogWithdraw(uint256 indexed tokenId, address to);

    event LogDepositTransfer(uint256 indexed tokenId, address to);

    event LogStake(uint256 tokenId, address refundee);

    event LogUnstake(uint256 tokenId, bytes32 incentiveId);

    event LogRewardClaimed(
        address rewardToken,
        address receiver,
        uint256 amount
    );

    event LogIncentiveCreated(
        address poolAddr,
        address refundee,
        uint256 startTime,
        uint256 endTime,
        uint256 reward
    );
}
