pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        uint256 indexed pid,
        uint256 indexed version,
        uint256 amount
    );
    event LogWithdraw(
        uint256 indexed pid,
        uint256 indexed version,
        uint256 amount
    );
    event LogEmergencyWithdraw(
        uint256 indexed pid,
        uint256 indexed version,
        uint256 lpAmount,
        uint256 rewardsAmount
    );
    event LogHarvest(
        uint256 indexed pid,
        uint256 indexed version,
        uint256 amount
    );
    event LogWithdrawAndHarvest(
        uint256 indexed pid,
        uint256 indexed version,
        uint256 widrawAmount,
        uint256 harvestAmount
    );
}
