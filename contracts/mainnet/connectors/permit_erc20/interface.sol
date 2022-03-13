pragma solidity ^0.7.6;

import { TokenInterface } from "../../common/interfaces.sol";

interface TokenInterfaceWithPermit is TokenInterface {
	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}

interface DAITokenInterfaceWithPermit is TokenInterface {
	function permit(
		address holder,
		address spender,
		uint256 nonce,
		uint256 expiry,
		bool allowed,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}
