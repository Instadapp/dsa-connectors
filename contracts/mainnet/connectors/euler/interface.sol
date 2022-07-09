//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IEulerMarkets {
	function enterMarket(uint256 subAccountId, address newMarket) external;

	function getEnteredMarkets(address account)
		external
		view
		returns (address[] memory);

	function exitMarket(uint256 subAccountId, address oldMarket) external;

	function underlyingToEToken(address underlying)
		external
		view
		returns (address);

	function underlyingToDToken(address underlying)
		external
		view
		returns (address);
}

interface IEulerEToken {
	function deposit(uint256 subAccountId, uint256 amount) external;

	function withdraw(uint256 subAccountId, uint256 amount) external;

	function decimals() external view returns (uint8);

	function mint(uint256 subAccountId, uint256 amount) external;

	function burn(uint256 subAccountId, uint256 amount) external;

	function balanceOf(address account) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function approve(address spender, uint256 amount) external returns (bool);
}

interface IEulerDToken {
	function underlyingToDToken(address underlying)
		external
		view
		returns (address);

	function decimals() external view returns (uint8);

	function borrow(uint256 subAccountId, uint256 amount) external;

	function repay(uint256 subAccountId, uint256 amount) external;

	function balanceOf(address account) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function approveDebt(
		uint256 subAccountId,
		address spender,
		uint256 amount
	) external returns (bool);
}

struct Swap1InchParams {
		uint256 subAccountIdIn;
		uint256 subAccountIdOut;
		address underlyingIn;
		address underlyingOut;
		uint256 amount;
		uint256 amountOutMinimum;
		bytes payload;
}

interface IEulerSwap {
	function swap1Inch(Swap1InchParams memory) external;
}
