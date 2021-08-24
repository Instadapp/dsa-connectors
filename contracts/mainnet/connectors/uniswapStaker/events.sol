pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        uint256 indexed tokenId,
        uint256 liquidity,
        uint256 amountA,
        uint256 amountB
    );

    event LogWithdraw(
        uint256 indexed tokenId,
        uint256 liquidity,
        uint256 amountA,
        uint256 amountB
    );

    event LogStake(uint256 tokenId, address refundee);

    event LogUnstake(uint256 tokenId, bytes32 incentiveId);

    event LogRewardClaimed(
        address rewardToken,
        address receiver,
        uint256 amount
    );

    event LogIncentiveCreated(
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 reward
    );
}
