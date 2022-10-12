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

	event LogBorrow(
		bool isETH,
		address poolTokenAddress,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		bool isETH,
		address poolTokenAddress,
		uint256 amt,
		uint256 getId,
		uint256 setId
	);

	event LogPayback(
		bool isETH,
		address poolTokenAddress,
		uint256 amt,
		uint256 getId,
		uint256 setId
	);

	event LogClaimed(address[] tokenAddresses, bool tradeForMorphoToken);
}
