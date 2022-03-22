//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
	uint256 constant WAD = 10**18;
	uint256 constant RAY = 10**27;

	function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(x, y);
	}

	function sub(uint256 x, uint256 y)
		internal
		pure
		virtual
		returns (uint256 z)
	{
		z = SafeMath.sub(x, y);
	}

	function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.mul(x, y);
	}

	function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.div(x, y);
	}

	function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
	}

	function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
	}

	function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
	}

	function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
	}

	function toInt(uint256 x) internal pure returns (int256 y) {
		y = int256(x);
		require(y >= 0, "int-overflow");
	}

	function toRad(uint256 wad) internal pure returns (uint256 rad) {
		rad = mul(wad, 10**27);
	}
}
