//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
	event LogDeposit(
		uint256 pool,
		address tokenAddress,
		address poolTokenAddress,
		uint256 amount,
		uint256 maxGasForMatching,
		uint256 getId,
		uint256 setId
	);

	event LogBorrow(
		uint256 pool,
		address poolTokenAddress,
		uint256 amount,
		uint256 maxGasForMatching,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		uint256 pool,
		bool isETH,
		address poolTokenAddress,
		uint256 amt,
		uint256 getId,
		uint256 setId
	);

	event LogPayback(
		uint256 pool,
		bool isETH,
		address poolTokenAddress,
		uint256 amt,
		uint256 getId,
		uint256 setId
	);

	event LogClaimed(
		uint256 pool,
		address[] tokenAddresses,
		bool tradeForMorphoToken
	);
}
