// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

contract Events {
	event LogMorphoCompoundImport(
		address indexed user,
		address[] supplyCTokens,
		address[] borrowCTokens,
		uint256[] supplyAmts,
		uint256[] borrowAmts
	);
}
