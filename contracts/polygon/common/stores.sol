//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { MemoryInterface, InstaMapping, ListInterface, InstaConnectors } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal maticAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wmaticAddr = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x6C7256cf7C003dD85683339F75DdE9971f98f2FD);

  /**
   * @dev Return InstaList address
   */
  ListInterface internal constant instaList = ListInterface(0x839c2D3aDe63DF5b0b8F3E57D5e145057Ab41556);

  /**
	 * @dev Return connectors registry address
	 */
	InstaConnectors internal constant instaConnectors = InstaConnectors(0x2A00684bFAb9717C21271E0751BCcb7d2D763c88);
  
  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}
