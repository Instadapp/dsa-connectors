//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
	event LogSparkImport(
		address indexed user,
		address[] stokens,
		string[] supplyIds,
		string[] borrowIds,
		uint256[] flashLoanFees,
		uint256[] supplyAmts,
		uint256[] borrowAmts
	);
	event LogSparkImportWithCollateral(
		address indexed user,
		address[] stokens,
		string[] supplyIds,
		string[] borrowIds,
		uint256[] flashLoanFees,
		uint256[] supplyAmts,
		uint256[] borrowAmts,
		bool[] enableCollateral
	);
}
