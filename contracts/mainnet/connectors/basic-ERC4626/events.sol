//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogDeposit(
		address indexed caller,
		address indexed owner,
		uint256 assets,
		uint256 shares
	);

	event LogWithdraw(
		address indexed caller,
		address indexed receiver,
		address indexed owner,
		uint256 assets,
		uint256 shares
	);

}
