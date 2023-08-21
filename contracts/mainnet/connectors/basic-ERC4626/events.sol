//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogDeposit(
		address indexed token,
		uint256 underlyingAmt,
		uint256 minSharesPerToken,
		uint256 sharesReceieved,
		uint256 getId,
		uint256 setId
	);

	event LogMint(
		address indexed token,
		uint256 shareAmt,
		uint256 maxTokenPerShares,
		uint256 underlyingTokenAmount,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		address indexed token,
		uint256 underlyingAmt,
		uint256 maxSharesPerToken,
		uint256 sharedBurned,
		address indexed to,
		uint256 getId,
		uint256 setId
	);

	event LogRedeem(
		address indexed token,
		uint256 shareAmt,
		uint256 minTokenPerShares,
		uint256 underlyingAmtReceieved,
		address to,
		uint256 getId,
		uint256 setId
	);
}