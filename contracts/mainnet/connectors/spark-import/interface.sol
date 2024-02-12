//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface SparkInterface {
	function supply(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	function withdraw(
		address _asset,
		uint256 _amount,
		address _to
	) external;

	function borrow(
		address _asset,
		uint256 _amount,
		uint256 _interestRateMode,
		uint16 _referralCode,
		address _onBehalfOf
	) external;

	function repay(
		address _asset,
		uint256 _amount,
		uint256 _rateMode,
		address _onBehalfOf
	) external;

	function setUserUseReserveAsCollateral(
		address _asset,
		bool _useAsCollateral
	) external;

	function swapBorrowRateMode(address _asset, uint256 _rateMode) external;
}

interface STokenInterface {
	function scaledBalanceOf(address _user) external view returns (uint256);

	function isTransferAllowed(address _user, uint256 _amount)
		external
		view
		returns (bool);

	function balanceOf(address _user) external view returns (uint256);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function allowance(address, address) external returns (uint256);
}

interface SparkPoolProviderInterface {
	function getPool() external view returns (address);
}

interface SparkDataProviderInterface {
	function getReserveTokensAddresses(address _asset)
		external
		view
		returns (
			address sTokenAddress,
			address stableDebtTokenAddress,
			address variableDebtTokenAddress
		);

	function getUserReserveData(address _asset, address _user)
		external
		view
		returns (
			uint256 currentSTokenBalance,
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

interface SparkAddressProviderRegistryInterface {
	function getAddressesProvidersList()
		external
		view
		returns (address[] memory);
}
