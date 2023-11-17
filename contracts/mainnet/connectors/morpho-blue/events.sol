//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {

	event LogSupply(
		address loanToken,
		uint256 assets,
        uint256 shares,
        address onBehalf,
        bytes data,
		uint256 getId,
		uint256 setId
	);

	event LogSupplyCollateral(
		address loanToken,
		address poolTokenAddress,
		uint256 amount,
		uint256 maxGasForMatching,
		uint256 getId,
		uint256 setId
	);

	event LogBorrow(
		address loanToken,
		uint256 amounts,
		uint256 shares,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		address loanToken,
		uint256 amounts,
		uint256 shares,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawCollateral(
		address loanToken,
		uint256 amounts,
		address onBehalf,
		uint256 getId,
		uint256 setId
	);

	event LogPayback(
		address loanToken,
		uint256 amounts,
		uint256 shares,
		address onBehalf,
		bytes data,
		uint256 getId,
		uint256 setId
	);
}
