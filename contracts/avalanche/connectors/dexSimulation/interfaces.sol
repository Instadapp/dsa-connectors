//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface InstaDexSimulation {
	function swap(
		address sellToken,
		address buyToken,
		uint256 sellAmount,
		uint256 buyAmount
	) external payable;
}
