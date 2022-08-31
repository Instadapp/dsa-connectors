//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogDeposit(
		address indexed market,
		address indexed token,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogDepositOnBehalfOf(
		address indexed market,
		address indexed token,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogDepositFrom(
		address indexed market,
		address indexed token,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		address indexed market,
		address indexed token,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawOnBehalfOf(
		address indexed market,
		address indexed token,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawFrom(
		address indexed market,
		address indexed token,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBorrow(
		address indexed market,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowOnBehalfOf(
		address indexed market,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowFrom(
		address indexed market,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogPayback(address indexed market, uint256 tokenAmt, uint256 setId);

	event LogPaybackOnBehalfOf(
		address indexed market,
		address to,
		uint256 tokenAmt,
		uint256 setId
	);

	event LogPaybackFrom(
		address indexed market,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 setId
	);

	event LogRewardsClaimed(
		address indexed market,
		address indexed account,
		uint256 indexed totalClaimedInWei,
		uint256 getId,
		bool accrued
	);

	event LogRewardsClaimedTo(
		address indexed market,
		address indexed account,
		address to,
		uint256 indexed totalClaimedInWei,
		uint256 getId,
		bool accrued
	);

	event LogLiquidate(
		address indexed borrower,
		address indexed tokenToPay,
		address indexed tokenInReturn,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBuyCollateral(
		address indexed market,
		address indexed token,
		uint256 indexed baseAmount,
		uint256 minCollateralAmt,
		uint256 collateralAmount,
		uint256 getId,
		uint256 setId
	);

	event LogTransferBase(
		address indexed market,
		address indexed dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogTransferBaseFrom(
		address indexed market,
		address indexed from,
		address indexed dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogTransferAsset(
		address indexed market,
		address token,
		address indexed from,
		address indexed dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogTransferAssetFrom(
		address indexed market,
		address token,
		address indexed from,
		address indexed dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogAllow(
		address indexed market,
		address indexed manager,
		bool allow
	);

	event LogAllowWithPermit(
		address indexed market,
		address indexed owner,
		address indexed manager,
		uint256 expiry,
		uint256 nonce,
		uint256 v,
		uint256 r,
		uint256 s,
		bool allow
	);
}
