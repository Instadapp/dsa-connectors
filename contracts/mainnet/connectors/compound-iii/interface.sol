//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

struct UserCollateral {
	uint128 balance;
	uint128 _reserved;
}

interface CometInterface {
	function supply(address asset, uint256 amount) external virtual;

	function supplyTo(
		address dst,
		address asset,
		uint256 amount
	) external virtual;

	function supplyFrom(
		address from,
		address dst,
		address asset,
		uint256 amount
	) external virtual;

	function transfer(address dst, uint256 amount)
		external
		virtual
		returns (bool);

	function transferFrom(
		address src,
		address dst,
		uint256 amount
	) external virtual returns (bool);

	function transferAsset(
		address dst,
		address asset,
		uint256 amount
	) external virtual;

	function transferAssetFrom(
		address src,
		address dst,
		address asset,
		uint256 amount
	) external virtual;

	function withdraw(address asset, uint256 amount) external virtual;

	function withdrawTo(
		address to,
		address asset,
		uint256 amount
	) external virtual;

	function withdrawFrom(
		address src,
		address to,
		address asset,
		uint256 amount
	) external virtual;

	function approveThis(
		address manager,
		address asset,
		uint256 amount
	) external virtual;

	function withdrawReserves(address to, uint256 amount) external virtual;

	function absorb(address absorber, address[] calldata accounts)
		external
		virtual;

	function buyCollateral(
		address asset,
		uint256 minAmount,
		uint256 baseAmount,
		address recipient
	) external virtual;

	function quoteCollateral(address asset, uint256 baseAmount)
		public
		view
		virtual
		returns (uint256);

	function userCollateral(address, address)
		external
		returns (UserCollateral memory);

	function baseToken() external view returns (address);

	function balanceOf(address account) external view returns (uint256);
}
