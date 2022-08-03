//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
	event LogEulerImport(
		address indexed user,
        uint256 indexed sourceId,
        uint256 indexed targetId,
		address[] supplyTokens,
		address[] borrowTokens,
		uint256[] supplyAmts,
		uint256[] borrowAmts,
		bool[] enterMarket
	);
}
