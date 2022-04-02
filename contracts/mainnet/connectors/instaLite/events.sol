//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogSupply(
		address vaultAddress,
		address token,
		uint256 vTokenAmt,
		uint256 amt,
		uint256 getId,
		uint256[] setIds
	);
	event LogWithdraw(
		address vaultAddress,
		uint256 amt,
		uint256 vTokenAmt,
		uint256 getId,
		uint256[] setIds
	);
}
