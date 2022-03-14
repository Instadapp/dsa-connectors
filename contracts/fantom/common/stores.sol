pragma solidity ^0.7.0;

import { MemoryInterface } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return FTM address
   */
  address constant internal ftmAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped FTM address
   */
  address constant internal wftmAddr = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x56439117379A53bE3CC2C55217251e2481B7a1C8);

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
