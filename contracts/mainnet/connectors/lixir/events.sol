pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        address indexed vault,
        uint256 shares,
        uint256 amount0In,
        uint256 amount1In
    );

    event LogWithdraw(
        uint256 indexed withdrawer,
        uint256 indexed recipient,
        uint256 shares,
        uint256 amount0Out,
        uint256 amount1Out
    );
}