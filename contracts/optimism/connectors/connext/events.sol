//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogXCall(
		uint32 indexed destination,
		address to,
		address asset,
		address delegate,
		uint256 indexed amount,
		uint256 slippage,
		uint256 getId,
		uint256 setId
	);
}
