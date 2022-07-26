//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogSwap(
		address buyToken,
		address sellToken,
		uint256 buyAmt,
		uint256 sellAmt,
		uint256 setId
	);
}
