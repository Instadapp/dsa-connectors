// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogDeposit(
		address token1,
		address token2,
		uint256 indexed pid,
		uint256 indexed version,
		uint256 amount
	);
	event LogWithdraw(
		address token1,
		address token2,
		uint256 indexed pid,
		uint256 indexed version,
		uint256 amount
	);
	event LogEmergencyWithdraw(
		address token1,
		address token2,
		uint256 indexed pid,
		uint256 indexed version,
		uint256 lpAmount,
		uint256 rewardsAmount
	);
	event LogHarvest(
		address token1,
		address token2,
		uint256 indexed pid,
		uint256 indexed version,
		uint256 amount
	);
	event LogWithdrawAndHarvest(
		address token1,
		address token2,
		uint256 indexed pid,
		uint256 indexed version,
		uint256 widrawAmount,
		uint256 harvestAmount
	);
}
