//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { MemoryInterface, ListInterface, InstaConnectors } from "./interfaces.sol";

abstract contract Stores {
	/**
	 * @dev Return FTM address
	 */
	address internal constant ftmAddr =
		0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	/**
	 * @dev Return Wrapped FTM address
	 */
	address internal constant wftmAddr =
		0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

	/**
	 * @dev Return memory variable address
	 */
	MemoryInterface internal constant instaMemory =
		MemoryInterface(0x56439117379A53bE3CC2C55217251e2481B7a1C8);

	/**
	 * @dev Return InstaList address
	 */
	ListInterface internal constant instaList = ListInterface(0x10e166c3FAF887D8a61dE6c25039231eE694E926);

	/**
	 * @dev Return connectors registry address
	 */
	InstaConnectors internal constant instaConnectors = InstaConnectors(0x819910794a030403F69247E1e5C0bBfF1593B968);

	/**
	 * @dev Get Uint value from InstaMemory Contract.
	 */
	function getUint(uint256 getId, uint256 val)
		internal
		returns (uint256 returnVal)
	{
		returnVal = getId == 0 ? val : instaMemory.getUint(getId);
	}

	/**
	 * @dev Set Uint value in InstaMemory Contract.
	 */
	function setUint(uint256 setId, uint256 val) internal virtual {
		if (setId != 0) instaMemory.setUint(setId, val);
	}
}
