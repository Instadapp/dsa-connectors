//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";

abstract contract Helpers is Stores, Basic {
	/**
	 * @dev dexSimulation Address
	 */
	address internal constant dexSimulation =
		0x718365C3d1aA4c5CcE869E16bE3f6A96EC65200b;
}
