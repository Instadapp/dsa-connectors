// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

contract Events {
	event LogRewardsClaimed(
		address indexed market,
		address indexed account,
		uint256 indexed totalClaimedInWei,
		uint256 getId,
		bool accrued
	);

	event LogRewardsClaimedTo(
		address indexed market,
		address indexed account,
		address to,
		uint256 indexed totalClaimedInWei,
		uint256 getId,
		bool accrued
	);
}
