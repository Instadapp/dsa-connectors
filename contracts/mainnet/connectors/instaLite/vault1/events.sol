//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogSupply(
		address token,
		uint256 vTokenAmt,
		uint256 amt,
		address to,
		uint256 getId,
		uint256 setId
	);
	event LogWithdraw(
		uint256 amt,
		uint256 vTokenAmt,
		address to,
		uint256 getId,
		uint256 setId
	);
}
