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

	event LogDepositFromUsingManager(
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

	event LogWithdrawTo(
		address indexed market,
		address indexed token,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawFromUsingManager(
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

	event LogBorrowFromUsingManager(
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

	event LogPaybackFromUsingManager(
		address indexed market,
		address from,
		address to,
		uint256 tokenAmt,
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

	event LogTransferAsset(
		address indexed market,
		address token,
		address indexed from,
		address indexed dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogTransferAssetFromUsingManager(
		address indexed market,
		address token,
		address indexed from,
		address indexed dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogAllow(address indexed market, address indexed manager, bool allow);

	event LogAllowWithPermit(
		address indexed market,
		address indexed owner,
		address indexed manager,
		bool allow,
		uint256 expiry,
		uint256 nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	);
}
