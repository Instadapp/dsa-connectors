//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AaveInterface {
	function supply(
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
		uint256 interestRateMode,
		address onBehalfOf
	) external returns (uint256);

	function repayWithATokens(
		address asset,
		uint256 amount,
		uint256 interestRateMode
	) external returns (uint256);

	function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
		external;

	function swapBorrowRateMode(address asset, uint256 interestRateMode)
		external;

	function setUserEMode(uint8 categoryId) external;
}

interface AavePoolProviderInterface {
	function getPool() external view returns (address);
}

interface AaveDataProviderInterface {
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

	function getReserveEModeCategory(address asset)
		external
		view
		returns (uint256);
}

interface AaveAddressProviderRegistryInterface {
	function getAddressesProvidersList()
		external
		view
		returns (address[] memory);
}

interface ATokenInterface {
	function balanceOf(address _user) external view returns (uint256);
}

interface DTokenInterface {
	function approveDelegation(address delegatee, uint256 amount) external;
}
