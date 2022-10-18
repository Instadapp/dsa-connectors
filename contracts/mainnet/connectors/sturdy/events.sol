//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdraw(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogBorrow(address indexed token, uint256 tokenAmt, uint256 indexed rateMode, uint256 getId, uint256 setId);
    event LogRepay(address indexed token, uint256 tokenAmt, uint256 indexed rateMode, uint256 getId, uint256 setId);
    event LogRepayOnBehalfOf(
		address token,
		uint256 amt,
		uint256 rateMode,
		address onBehalfOf,
		uint256 getId,
		uint256 setId
	);
  event LogDepositCollateral(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
  event LogWithdrawCollateral(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
}
