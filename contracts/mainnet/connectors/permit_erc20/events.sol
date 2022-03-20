pragma solidity ^0.7.0;

contract Events {
	event logDepositWithPermit(
		address token,
		address owner,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s,
		uint256 getId,
		uint256 setId
	);
}
