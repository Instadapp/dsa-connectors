pragma solidity ^0.7.0;

contract Events {
	event LogAaveImportV2ToV3(
		address indexed user,
		bool doImport,
		bool convertStable,
		address[] supplyTokensV2,
		address[] supplyTokensV3,
		address[] borrowTokensV2,
		address[] borrowTokensV3,
		uint256[] flashLoanFees,
		uint256[] supplyAmts,
		uint256[] stableBorrowAmts,
		uint256[] variableBorrowAmts
	);
}
