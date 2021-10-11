// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract Events {
    event Deposit(
        address indexed userAddress,
        address indexed token,
        uint256 amount,
        uint256 lpAmount,
        uint256 durationWeeks,
        uint256 indexed bondingShareId,
        uint256 getId,
        uint256 setId
    );
}
