//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogWithdraw(
		address indexed erc20,
		uint256 tokenAmt,
		address indexed to,
		uint256 getId,
		uint256 setId
	);
	event LogRedeem(
		address indexed erc20,
		uint256 tokenAmt,
		address indexed to,
		uint256 getId,
		uint256 setId
	);
	event LogDeposit(
		address indexed erc20,
		uint256 tokenAmt,
		address indexed receiver,
		address indexed owner,
		uint256 getId,
		uint256 setId
	);
	event LogMint(
		address indexed erc20,
		uint256 tokenAmt,
		address indexed receiver,
		address indexed owner,
		uint256 getId,
		uint256 setId
	);
}
