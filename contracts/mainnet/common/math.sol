//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toUint(int256 x) internal pure returns (uint256) {
      require(x >= 0, "int-overflow");
      return uint256(x);
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }
  
	function toUint96(uint256 value) internal pure returns (uint96) {
		require(value <= type(uint96).max, "uint96 value overflow");
		return uint96(value);
	}

	function toUint88(uint256 value) internal pure returns (uint88) {
		require(value <= type(uint88).max, "uint88-overflow");
		return uint88(value);
	}

	function toUint32(uint256 value) internal pure returns (uint32) {
		require(value <= type(uint32).max, "uint32-overflow");
		return uint32(value);
	}

	function toUint16(uint256 value) internal pure returns (uint16) {
		require(value <= type(uint16).max, "uint16-overflow");
		return uint16(value);
	}

	function toUint8(uint256 value) internal pure returns (uint8) {
		require(value <= type(uint8).max, "uint8-overflow");
		return uint8(value);
	}

}
