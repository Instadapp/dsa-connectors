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

	event LogDepositOnBehalf(
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

	event LogWithdrawOnBehalf(
		address indexed market,
		address indexed token,
		address from,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawOnBehalfAndTransfer(
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

	event LogBorrowTo(
		address indexed market,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowOnBehalf(
		address indexed market,
		address from,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowOnBehalfAndTransfer(
		address indexed market,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogPayback(address indexed market, uint256 tokenAmt, uint256 getId, uint256 setId);

	event LogPaybackOnBehalf(
		address indexed market,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogPaybackFromUsingManager(
		address indexed market,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBuyCollateral(
		address indexed market,
		address indexed buyToken,
		uint256 indexed baseSellAmt,
		uint256 unitAmt,
		uint256 buyAmount,
		uint256 getId,
		uint256 setId
	);

	event LogTransferAsset(
		address indexed market,
		address token,
		address indexed dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogTransferAssetOnBehalf(
		address indexed market,
		address token,
		address indexed from,
		address indexed dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogToggleAccountManager(
		address indexed market,
		address indexed manager,
		bool allow
	);

	event LogToggleAccountManagerWithPermit(
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
