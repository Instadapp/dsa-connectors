// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface TokenInterface {
	function balanceOf(address) external view returns (uint256);

	function allowance(address, address) external view returns (uint256);

	function approve(address, uint256) external;

	function transfer(address, uint256) external returns (bool);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);
}

interface CTokenInterface {
	function underlying() external view returns (address);

	function mint(uint256 mintAmount) external returns (uint256);

	function redeem(uint256 redeemTokens) external returns (uint256);

	function borrow(uint256 borrowAmount) external returns (uint256);

	function balanceOf(address owner) external view returns (uint256 balance);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function approve(address spender, uint256 amount) external returns (bool);
}

interface IMorphoLens {
	function getCurrentSupplyBalanceInOf(address _poolToken, address _user)
		external
		view
		returns (
			uint256 balanceOnPool,
			uint256 balanceInP2P,
			uint256 totalBalance
		);

	function getCurrentBorrowBalanceInOf(address _poolToken, address _user)
		external
		view
		returns (
			uint256 balanceOnPool,
			uint256 balanceInP2P,
			uint256 totalBalance
		);
}

interface CETHInterface {
	function mint() external payable;

	function repayBorrow() external payable;

	function repayBorrowBehalf(address borrower) external payable;

	function liquidateBorrow(address borrower, address cTokenCollateral)
		external
		payable;
}

interface IMorpho {
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
