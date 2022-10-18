//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IMorphoCore {
	function supply(
		address _poolTokenAddress,
		address _onBehalf,
		uint256 _amount
	) external;

	function supply(
		address _poolTokenAddress,
		address _onBehalf,
		uint256 _amount,
		uint256 _maxGasForMatching
	) external;

	function borrow(address _poolTokenAddress, uint256 _amount) external;

	function borrow(
		address _poolTokenAddress,
		uint256 _amount,
		uint256 _maxGasForMatching
	) external;

	function withdraw(address _poolTokenAddress, uint256 _amount) external;

	function repay(
		address _poolTokenAddress,
		address _onBehalf,
		uint256 _amount
	) external;
}

interface IMorphoCompoundLens {
	function getCurrentBorrowBalanceInOf(
		address _poolTokenAddress,
		address _user
	)
		external
		view
		returns (
			uint256 balanceOnPool,
			uint256 balanceInP2P,
			uint256 totalBalance
		);

	function getCurrentSupplyBalanceInOf(
		address _poolTokenAddress,
		address _user
	)
		external
		view
		returns (
			uint256 balanceOnPool,
			uint256 balanceInP2P,
			uint256 totalBalance
		);
}
