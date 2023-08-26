//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
	event LogAaveV3Import(
		address indexed user,
		address[] ctokens,
		string[] supplyIds,
		string[] borrowIds,
		uint256[] flashLoanFees,
		uint256[] supplyAmts,
		uint256[] borrowAmts
	);
	event LogAaveV3ImportWithCollateral(
		address indexed user,
		address[] atokens,
		string[] supplyIds,
		string[] borrowIds,
		uint256[] flashLoanFees,
		uint256[] supplyAmts,
		uint256[] borrowAmts,
		bool[] enableCollateral
	);
}
