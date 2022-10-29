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

	function repayBorrow(uint256 repayAmount) external returns (uint256);

	function repayBorrowBehalf(address borrower, uint256 repayAmount)
		external
		returns (uint256); // For ERC20

	function liquidateBorrow(
		address borrower,
		uint256 repayAmount,
		address cTokenCollateral
	) external returns (uint256);

	function borrowBalanceCurrent(address account) external returns (uint256);

	function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

	function exchangeRateCurrent() external returns (uint256);

	function balanceOf(address owner) external view returns (uint256 balance);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function allowance(address, address) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);
}

interface IMorphoLens {
	function MAX_BASIS_POINTS() external view returns (uint256);

	function WAD() external view returns (uint256);

	function morpho() external view returns (IMorpho);

	function comptroller() external view returns (IComptroller);

	function getTotalSupply()
		external
		view
		returns (
			uint256 p2pSupplyAmount,
			uint256 poolSupplyAmount,
			uint256 totalSupplyAmount
		);

	function getTotalBorrow()
		external
		view
		returns (
			uint256 p2pBorrowAmount,
			uint256 poolBorrowAmount,
			uint256 totalBorrowAmount
		);

	function isMarketCreated(address _poolToken) external view returns (bool);

	function isMarketCreatedAndNotPaused(address _poolToken)
		external
		view
		returns (bool);

	function isMarketCreatedAndNotPausedNorPartiallyPaused(address _poolToken)
		external
		view
		returns (bool);

	function getAllMarkets()
		external
		view
		returns (address[] memory marketsCreated_);

	function getMainMarketData(address _poolToken)
		external
		view
		returns (
			uint256 avgSupplyRatePerBlock,
			uint256 avgBorrowRatePerBlock,
			uint256 p2pSupplyAmount,
			uint256 p2pBorrowAmount,
			uint256 poolSupplyAmount,
			uint256 poolBorrowAmount
		);

	function getTotalMarketSupply(address _poolToken)
		external
		view
		returns (uint256 p2pSupplyAmount, uint256 poolSupplyAmount);

	function getTotalMarketBorrow(address _poolToken)
		external
		view
		returns (uint256 p2pBorrowAmount, uint256 poolBorrowAmount);

	function getCurrentP2PSupplyIndex(address _poolToken)
		external
		view
		returns (uint256);

	function getCurrentP2PBorrowIndex(address _poolToken)
		external
		view
		returns (uint256);

	function getCurrentPoolIndexes(address _poolToken)
		external
		view
		returns (
			uint256 currentPoolSupplyIndex,
			uint256 currentPoolBorrowIndex
		);

	function getIndexes(address _poolToken, bool _computeUpdatedIndexes)
		external
		view
		returns (
			uint256 p2pSupplyIndex,
			uint256 p2pBorrowIndex,
			uint256 poolSupplyIndex,
			uint256 poolBorrowIndex
		);

	function getEnteredMarkets(address _user)
		external
		view
		returns (address[] memory enteredMarkets);

	function getUserMaxCapacitiesForAsset(address _user, address _poolToken)
		external
		view
		returns (uint256 withdrawable, uint256 borrowable);

	function getUserHypotheticalBalanceStates(
		address _user,
		address _poolToken,
		uint256 _withdrawnAmount,
		uint256 _borrowedAmount
	) external view returns (uint256 debtValue, uint256 maxDebtValue);

	function getUserLiquidityDataForAsset(
		address _user,
		address _poolToken,
		bool _computeUpdatedIndexes,
		ICompoundOracle _oracle
	) external view returns (AssetLiquidityData memory assetData);

	function computeLiquidationRepayAmount(
		address _user,
		address _poolTokenBorrowed,
		address _poolTokenCollateral,
		address[] calldata _updatedMarkets
	) external view returns (uint256 toRepay);

	function getAverageSupplyRatePerBlock(address _poolToken)
		external
		view
		returns (uint256);

	function getAverageBorrowRatePerBlock(address _poolToken)
		external
		view
		returns (uint256);

	function getNextUserSupplyRatePerBlock(
		address _poolToken,
		address _user,
		uint256 _amount
	)
		external
		view
		returns (
			uint256 nextSupplyRatePerBlock,
			uint256 balanceOnPool,
			uint256 balanceInP2P,
			uint256 totalBalance
		);

	function getNextUserBorrowRatePerBlock(
		address _poolToken,
		address _user,
		uint256 _amount
	)
		external
		view
		returns (
			uint256 nextBorrowRatePerBlock,
			uint256 balanceOnPool,
			uint256 balanceInP2P,
			uint256 totalBalance
		);

	function getMarketConfiguration(address _poolToken)
		external
		view
		returns (
			address underlying,
			bool isCreated,
			bool p2pDisabled,
			bool isPaused,
			bool isPartiallyPaused,
			uint16 reserveFactor,
			uint16 p2pIndexCursor,
			uint256 collateralFactor
		);

	function getRatesPerBlock(address _poolToken)
		external
		view
		returns (
			uint256 p2pSupplyRate,
			uint256 p2pBorrowRate,
			uint256 poolSupplyRate,
			uint256 poolBorrowRate
		);

	function getAdvancedMarketData(address _poolToken)
		external
		view
		returns (
			uint256 p2pSupplyIndex,
			uint256 p2pBorrowIndex,
			uint256 poolSupplyIndex,
			uint256 poolBorrowIndex,
			uint32 lastUpdateBlockNumber,
			uint256 p2pSupplyDelta,
			uint256 p2pBorrowDelta
		);

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

	function getUserBalanceStates(
		address _user,
		address[] calldata _updatedMarkets
	)
		external
		view
		returns (
			uint256 collateralValue,
			uint256 debtValue,
			uint256 maxDebtValue
		);

	function getAccruedSupplierComp(
		address _supplier,
		address _poolToken,
		uint256 _balance
	) external view returns (uint256);

	function getAccruedBorrowerComp(
		address _borrower,
		address _poolToken,
		uint256 _balance
	) external view returns (uint256);

	function getCurrentCompSupplyIndex(address _poolToken)
		external
		view
		returns (uint256);

	function getCurrentCompBorrowIndex(address _poolToken)
		external
		view
		returns (uint256);

	function getUserUnclaimedRewards(
		address[] calldata _poolTokens,
		address _user
	) external view returns (uint256 unclaimedRewards);

	function isLiquidatable(address _user, address[] memory _updatedMarkets)
		external
		view
		returns (bool);

	function getCurrentUserSupplyRatePerBlock(address _poolToken, address _user)
		external
		view
		returns (uint256);

	function getCurrentUserBorrowRatePerBlock(address _poolToken, address _user)
		external
		view
		returns (uint256);

	function getUserHealthFactor(
		address _user,
		address[] calldata _updatedMarkets
	) external view returns (uint256);
}

interface CETHInterface {
	function mint() external payable;

	function repayBorrow() external payable;

	function repayBorrowBehalf(address borrower) external payable;

	function liquidateBorrow(address borrower, address cTokenCollateral)
		external
		payable;
}

interface ComptrollerInterface {
	function enterMarkets(address[] calldata cTokens)
		external
		returns (uint256[] memory);

	function exitMarket(address cTokenAddress) external returns (uint256);

	function getAssetsIn(address account)
		external
		view
		returns (address[] memory);

	function getAccountLiquidity(address account)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);
}

interface CompoundMappingInterface {
	function cTokenMapping(string calldata tokenId)
		external
		view
		returns (address);

	function getMapping(string calldata tokenId)
		external
		view
		returns (address, address);
}
