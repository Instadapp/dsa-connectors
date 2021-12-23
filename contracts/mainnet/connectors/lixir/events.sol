pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        address indexed depositor,
        address indexed recipient,
        uint256 shares,
        uint256 amount0In,
        uint256 amount1In,
        uint256 total0,
        uint256 total1
    );

    event LogWithdraw(
        uint256 indexed withdrawer,
        uint256 indexed recipient,
        uint256 shares,
        uint256 amount0Out,
        uint256 amount1Out,
    );
}