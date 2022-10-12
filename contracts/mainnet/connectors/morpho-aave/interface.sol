//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IMorphoCore {
	function supply(
		address _poolTokenAddress,
		address _onBehalf,
		uint256 _amount
	) external;

	function borrow(address _poolTokenAddress, uint256 _amount) external;

	function withdraw(address _poolTokenAddress, uint256 _amount) external;

	function repay(
		address _poolTokenAddress,
		address _onBehalf,
		uint256 _amount
	) external;

	function liquidate(
		address _poolTokenBorrowedAddress,
		address _poolTokenCollateralAddress,
		address _borrower,
		uint256 _amount
	) external;

	function claimRewards(
		address[] calldata _tokenAddresses,
		bool _tradeForMorphoToken
	) external;
}

interface IMorphoAaveLens {
	function _getCurrentBorrowBalanceInOf(address _poolToken, address _user)
		external
		view
		returns (
			address underlyingToken,
			uint256 balanceInP2P,
			uint256 balanceOnPool,
			uint256 totalBalance
		);

	function _getCurrentSupplyBalanceInOf(address _poolToken, address _user)
		external
		view
		returns (
			address underlyingToken,
			uint256 balanceInP2P,
			uint256 balanceOnPool,
			uint256 totalBalance
		);
}
