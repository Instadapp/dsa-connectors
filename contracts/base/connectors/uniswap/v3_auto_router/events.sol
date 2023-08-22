pragma solidity ^0.7.0;

contract Events {
	event LogSwap(
		address indexed buyToken,
		address indexed sellToken,
		uint256 buyAmt,
		uint256 sellAmt,
		uint256 getId,
		uint256 setId
	);
}
