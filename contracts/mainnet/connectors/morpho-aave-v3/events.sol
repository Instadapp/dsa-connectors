//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
	event LogDeposit(
		address tokenAddress,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogDepositWithMaxIterations(
		address tokenAddress,
		uint256 amount,
		uint256 maxIteration,
		uint256 getId,
		uint256 setId
	);

	event LogDepositOnBehalfWithMaxIterations(
		address tokenAddress,
		uint256 amount,
		address onBehalf,
		uint256 maxIteration,
		uint256 getId,
		uint256 setId
	);

	event LogDepositCollateral(
		address tokenAddress,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogDepositCollateralOnBehalf(
		address tokenAddress,
		uint256 amount,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogBorrow(
		address tokenAddress,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowWithMaxIterations(
		address tokenAddress,
		uint256 amount,
		uint256 maxIteration,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowOnBehalfWithMaxIterations(
		address tokenAddress,
		uint256 amount,
		address onBehalf,
		address receiver,
		uint256 maxIteration,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		address tokenAddress,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawWithMaxIterations(
		address tokenAddress,
		uint256 amount,
		uint256 maxIteration,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawOnBehalfWithMaxIterations(
		address tokenAddress,
		uint256 amount,
		address onBehalf,
		address receiver,
		uint256 maxIteration,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawCollateral(
		address tokenAddress,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawCollateralOnBehalf(
		address tokenAddress,
		uint256 amount,
		address onBehalf,
		address receiver,
		uint256 getId,
		uint256 setId
	);

	event LogPayback(
		address tokenAddress,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogPaybackOnBehalf(
		address tokenAddress,
		uint256 amount,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogApproveManger(address manger, bool isAllowed);
}
