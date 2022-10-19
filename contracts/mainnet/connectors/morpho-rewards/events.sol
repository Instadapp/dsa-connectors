//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
	event LogClaimedMorpho(uint256 claimable, bytes32[] proofs);

	event LogClaimedAave(
		address[] poolTokenAddresses,
		bool tradeForMorphoToken,
		uint256 amountOfRewards,
		uint256 setId
	);

	event LogClaimedCompound(
		address[] poolTokenAddresses,
		bool tradeForMorphoToken,
		uint256 amountOfRewards,
		uint256 setId
	);
}
