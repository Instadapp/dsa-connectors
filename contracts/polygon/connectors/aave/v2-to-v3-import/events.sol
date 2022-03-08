pragma solidity ^0.7.0;

contract Events {
	event LogAaveV2ImportToV3(
		address indexed user,
		bool doImport,
		bool convertStable,
		address[] supplyTokens,
		address[] borrowTokens,
		uint256[] flashLoanFees,
		uint256[] supplyAmts,
		uint256[] stableBorrowAmts,
		uint256[] variableBorrowAmts
	);
}
