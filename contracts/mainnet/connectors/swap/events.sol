//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogSwapAggregator(
		string _connector,
		address indexed buyToken,
		address indexed sellToken,
		uint256 buyAmt,
		uint256 sellAmt,
		uint256 setId
	);
}
