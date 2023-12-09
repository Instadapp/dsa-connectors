//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./interface.sol";

contract Events {

	event LogSupplyAssets(
		MarketParams marketParams,
		uint256 assets,
        uint256 shares,
		uint256 getId,
		uint256 setId
	);

	event LogSupplyAssetsOnBehalf(
		MarketParams marketParams,
		uint256 assets,
        uint256 shares,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogSupplySharesOnBehalf(
		MarketParams marketParams,
		uint256 assets,
        uint256 shares,
        address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogSupplyCollateral(
		MarketParams marketParams,
		uint256 assets,
		uint256 getId,
		uint256 setId
	);

	event LogSupplyCollateralOnBehalf(
		MarketParams marketParams,
		uint256 assets,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogBorrow(
		MarketParams marketParams,
		uint256 amounts,
		uint256 shares,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowOnBehalf(
		MarketParams marketParams,
		uint256 amounts,
		uint256 shares,
		address onBehalf,
		address reciever,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowShares(
		MarketParams marketParams,
		uint256 amounts,
		uint256 shares,
		address onBehalf,
		address reciever,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		MarketParams marketParams,
		uint256 amounts,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawOnBehalf(
		MarketParams marketParams,
		uint256 amounts,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawSharesOnBehalf(
		MarketParams marketParams,
		uint256 shares,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawCollateral(
		MarketParams marketParams,
		uint256 amounts,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawCollateralOnBehalf(
		MarketParams marketParams,
		uint256 amounts,
		address onBehalf,
		address reciever,
		uint256 getId,
		uint256 setId
	);

	event LogPayback(
		MarketParams marketParams,
		uint256 amounts,
		uint256 shares,
		uint256 getId,
		uint256 setId
	);

	event LogPaybackOnBehalf(
		MarketParams marketParams,
		uint256 amounts,
		uint256 shares,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogPaybackShares(
		MarketParams marketParams,
		uint256 amounts,
		uint256 shares,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);
}
