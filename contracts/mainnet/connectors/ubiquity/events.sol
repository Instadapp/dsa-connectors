// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract Events {
	event LogDeposit(
		address indexed userAddress,
		address indexed token,
		uint256 amount,
		uint256 indexed bondingShareId,
		uint256 lpAmount,
		uint256 durationWeeks,
		uint256 getId,
		uint256 setId
	);
	event LogWithdraw(
		address indexed userAddress,
		uint256 indexed bondingShareId,
		uint256 lpAmount,
		uint256 endBlock,
		address indexed token,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);
}
