pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

contract Events {
	event LogAaveV3Import(
		address indexed user,
		address[] ctokens,
		string[] supplyIds,
		string[] borrowIds,
		uint256[] supplyAmts,
		uint256[] borrowAmts
	);
}
