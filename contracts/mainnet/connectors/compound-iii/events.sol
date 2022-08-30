//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogDeposit(
		address indexed market,
		address indexed asset,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogDepositOnBehalfOf(
		address indexed market,
		address indexed asset,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogDepositFrom(
		address indexed market,
		address indexed asset,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		address indexed market,
		address indexed asset,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawOnBehalfOf(
		address indexed market,
		address indexed asset,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawFrom(
		address indexed market,
		address indexed asset,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBorrow(
		address indexed market,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowOnBehalfOf(
		address indexed market,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowFrom(
		address indexed market,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogPayback(
		address indexed market,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogPaybackOnBehalfOf(
		address indexed market,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogPaybackFrom(
		address indexed market,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogRewardsClaimed(
		address indexed token,
		address cToken,
		uint256 tokenAmt,
		uint256 cTokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogLiquidate(
		address indexed borrower,
		address indexed tokenToPay,
		address indexed tokenInReturn,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);
}
