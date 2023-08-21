//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogDeposit(
		address indexed token,
		uint256 underlyingAmt,
		uint256 minSharesPerToken,
		uint256 getId,
		uint256 setId
	);

	event LogMint(
		address indexed token,
		uint256 shareAmt,
		uint256 maxTokenPerShares,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		address indexed token,
		uint256 underlyingAmt,
		uint256 maxSharesPerToken,
		address indexed to,
		uint256 getId,
		uint256 setId
	);

	event LogRedeem(
		address indexed token,
		uint256 shareAmt,
		uint256 minTokenPerShares,
		address to,
		uint256 getId,
		uint256 setId
	);
}
