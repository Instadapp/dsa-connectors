//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogSimulateSwap(
		address sellToken,
		address buyToken,
		uint256 sellAmount,
		uint256 buyAmount
	);
}
