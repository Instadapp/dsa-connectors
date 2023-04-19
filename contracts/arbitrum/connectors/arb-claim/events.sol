// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogArbAirdropClaimed(
		address indexed account,
		uint256 indexed claimable,
		uint256 setId
	);

	event LogArbTokensDelegated(
		address indexed account,
		address indexed delegatee
	);

	event LogArbTokensDelegatedBySig(
		address indexed account,
		address indexed delegatee,
		uint256 nonce
	);
}
