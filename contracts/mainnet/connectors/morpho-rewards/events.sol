//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
	event LogClaimedMorpho(
		address account,
		uint256 claimable,
		uint256 setId
	);

	event LogClaimedAave(
		address[] poolTokenAddresses,
		bool tradeForMorphoToken,
		uint256 amountOfRewards,
		uint256 setId
	);

	event LogClaimedMorphoAaveV3(
		address[] poolTokenAddresses,
		address onBehalf,
		address[] rewardTokens,
		uint256[] claimedAmounts
	);

	event LogClaimedCompound(
		address[] poolTokenAddresses,
		bool tradeForMorphoToken,
		uint256 amountOfRewards,
		uint256 setId
	);
}
