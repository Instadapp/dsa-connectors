//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
	event LogDeposit(
		address tokenAddress,
		address poolTokenAddress,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogDepositWithMaxGas(
		address tokenAddress,
		address poolTokenAddress,
		uint256 amount,
		uint256 maxGasForMatching,
		uint256 getId,
		uint256 setId
	);

	event LogDepositOnBehalf(
		address tokenAddress,
		address poolTokenAddress,
		address onBehalf,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogBorrow(
		address tokenAddress,
		address poolTokenAddress,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowWithMaxGas(
		address tokenAddress,
		address poolTokenAddress,
		uint256 amount,
		uint256 maxGasForMatching,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		address tokenAddress,
		address poolTokenAddress,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogPayback(
		address tokenAddress,
		address poolTokenAddress,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogPaybackOnBehalf(
		address tokenAddress,
		address poolTokenAddress,
		address onBehalf,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);
}
