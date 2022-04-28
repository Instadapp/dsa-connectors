//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogDeposit(
		address indexed token,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);
	event LogWithdraw(
		address indexed token,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);
	event LogBorrow(
		address indexed token,
		uint256 tokenAmt,
		uint256 indexed rateMode,
		uint256 getId,
		uint256 setId
	);
	event LogPayback(
		address indexed token,
		uint256 tokenAmt,
		uint256 indexed rateMode,
		uint256 getId,
		uint256 setId
	);
	event LogEnableCollateral(address[] tokens);
	event LogDisableCollateral(address[] tokens);
	event LogSwapRateMode(address indexed token, uint256 rateMode);
	event LogSetUserEMode(uint8 categoryId);
	event LogDelegateBorrow(
		address token,
		uint256 amount,
		uint256 rateMode,
		address delegateTo,
		uint256 getId,
		uint256 setId
	);
	event LogDepositWithoutCollateral(
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	);
	event LogBorrowOnBehalfOf(
		address token,
		uint256 amt,
		uint256 rateMode,
		address onBehalfOf,
		uint256 getId,
		uint256 setId
	);
	event LogPaybackOnBehalfOf(
		address token,
		uint256 amt,
		uint256 rateMode,
		address onBehalfOf,
		uint256 getId,
		uint256 setId
	);
}
