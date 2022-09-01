//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

struct UserCollateral {
	uint128 balance;
	uint128 _reserved;
}

struct RewardOwed {
	address token;
	uint256 owed;
}

interface CometRewards {
	function claim(
		address comet,
		address src,
		bool shouldAccrue
	) external;

	function claimTo(
		address comet,
		address src,
		address to,
		bool shouldAccrue
	) external;

	function getRewardOwed(address comet, address account)
		external
		returns (RewardOwed memory);

	function rewardsClaimed(address cometProxy, address account)
		external
		view
		returns (uint256);
}
