// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

struct MarketParams {
	address loanToken;
	address collateralToken;
	address oracle;
	address irm;
	uint256 lltv;
}

/// @dev Warning: For `feeRecipient`, `supplyShares` does not contain the accrued shares since the last interest
/// accrual.
struct Position {
	uint256 supplyShares;
	uint128 borrowShares;
	uint128 collateral;
}

/// @dev Warning: `totalSupplyAssets` does not contain the accrued interest since the last interest accrual.
/// @dev Warning: `totalBorrowAssets` does not contain the accrued interest since the last interest accrual.
/// @dev Warning: `totalSupplyShares` does not contain the additional shares accrued by `feeRecipient` since the last
/// interest accrual.
struct Market {
	uint128 totalSupplyAssets;
	uint128 totalSupplyShares;
	uint128 totalBorrowAssets;
	uint128 totalBorrowShares;
	uint128 lastUpdate;
	uint128 fee;
}

interface IMorpho {
	function createMarket(MarketParams memory marketParams) external;

	function supply(
		MarketParams memory marketParams,
		uint256 assets,
		uint256 shares,
		address onBehalf,
		bytes calldata data
	) external returns (uint256, uint256);

	function withdraw(
		MarketParams memory marketParams,
		uint256 assets,
		uint256 shares,
		address onBehalf,
		address receiver
	) external returns (uint256, uint256);

	function borrow(
		MarketParams memory marketParams,
		uint256 assets,
		uint256 shares,
		address onBehalf,
		address receiver
	) external returns (uint256, uint256);

	function repay(
		MarketParams memory marketParams,
		uint256 assets,
		uint256 shares,
		address onBehalf,
		bytes calldata data
	) external returns (uint256, uint256);

	function supplyCollateral(
		MarketParams memory marketParams,
		uint256 assets,
		address onBehalf,
		bytes calldata data
	) external;

	function withdrawCollateral(
		MarketParams memory marketParams,
		uint256 assets,
		address onBehalf,
		address receiver
	) external;

	function position(
		bytes32 id,
		address user
	) external view returns (Position memory);

	function market(bytes32 id) external view returns (Market memory);
}
