//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface SturdyAddressesProviderInterface {
	function getLendingPool() external view returns (address);

	function getAddress(bytes32 id) external view returns (address);
}

interface SturdyCollateralAdapterInterface {
	function getAcceptableVault(address _externalAsset)
		external
		view
		returns (address);
}

interface SturdyLendingPoolInterface {
	function deposit(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	function repay(
		address asset,
		uint256 amount,
		uint256 rateMode,
		address onBehalfOf
	) external returns (uint256);
}

interface SturdyVaultInterface {
	function depositCollateralFrom(address asset, uint256 amount, address onBehalfOf) external payable;

	function withdrawCollateral(
		address asset,
		uint256 amount,
		uint256 slippage,
		address to
	) external;
}

interface SturdyDataProviderInterface {
	function getReserveTokensAddresses(address _asset)
		external
		view
		returns (
			address aTokenAddress,
			address stableDebtTokenAddress,
			address variableDebtTokenAddress
		);

	function getUserReserveData(address _asset, address _user)
		external
		view
		returns (
			uint256 currentATokenBalance,
			uint256 currentStableDebt,
			uint256 currentVariableDebt,
			uint256 principalStableDebt,
			uint256 scaledVariableDebt,
			uint256 stableBorrowRate,
			uint256 liquidityRate,
			uint40 stableRateLastUpdated,
			bool usageAsCollateralEnabled
		);
}
