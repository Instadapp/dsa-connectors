//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogXCall(
		uint32 destination,
		address to,
		address asset,
		address delegate,
		uint256 amount,
		uint256 slippage,
		uint256 getId
	);
}
