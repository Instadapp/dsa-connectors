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

	event LogDepositOnBehalf(
		address tokenAddress,
		uint256 amount,
		address onBehalf,
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

	event LogDepositWithPermit(
		address tokenAddress,
		uint256 amount,
		address onBehalf,
		uint256 maxIteration,
		uint256 time,
		uint8 v,
		bytes32 r,
		bytes32 s,
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

	event LogDepositCollateralWithPermit(
		address tokenAddress,
		uint256 amount,
		address onBehalf,
		uint256 maxIteration,
		uint256 time,
		uint8 v,
		bytes32 r,
		bytes32 s,
		uint256 getId,
		uint256 setId
	);

	event LogBorrow(
		address tokenAddress,
		uint256 amount,
		address receiver,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowWithMaxIterations(
		address tokenAddress,
		uint256 amount,
		address receiver,
		uint256 maxIteration,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowOnBehalfWithMaxIterations(
		address tokenAddress,
		uint256 amount,
		address receiver,
		address onBehalf,
		uint256 maxIteration,
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
