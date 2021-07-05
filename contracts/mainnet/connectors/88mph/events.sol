pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        address indexed pool,
        uint256 amount,
        uint256 maturationTimestamp
    );

    event LogWithdraw(
        address indexed pool,
        uint256 depositID,
        uint256 fundingID
    );

    event LogWithdrawReward(uint256 indexed vestIdx);
}
