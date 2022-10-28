//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IMorphoCore {
	function claimRewards(
		address[] calldata _tokenAddresses,
		bool _tradeForMorphoToken
	) external returns (uint256 _claimedAmount);
}

interface IMorphoRewardsDistributor {
	function claim(
		address _account,
		uint256 _claimable,
		bytes32[] calldata _proof
	) external;
}
