pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        address indexed user,
        uint256 indexed pid,
        uint256 indexed version,
        uint256 amount
    );
    event LogWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 indexed version,
        uint256 amount
    );
    event LogEmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 indexed version,
        uint256 lpAmount,
        uint256 rewardsAmount
    );
    event LogHarvest(
        address indexed user,
        uint256 indexed pid,
        uint256 indexed version,
        uint256 amount
    );
    event LogWithdrawAndHarvest(
        address indexed user,
        uint256 indexed pid,
        uint256 indexed version,
        uint256 widrawAmount,
        uint256 harvestAmount
    );
}
