// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IArbitrumTokenDistributor {
	function claim() external;

	function claimAndDelegate(
		address delegatee,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function claimableTokens(address) external view returns (uint256);
}

interface IArbTokenContract {
	function delegate(address delegatee) external;

	function delegateBySig(
		address delegatee,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}

interface TokenInterface {
	function approve(address, uint256) external;

	function transfer(address, uint256) external;

	function transferFrom(
		address,
		address,
		uint256
	) external;

	function deposit() external payable;

	function withdraw(uint256) external;

	function balanceOf(address) external view returns (uint256);

	function decimals() external view returns (uint256);
}
