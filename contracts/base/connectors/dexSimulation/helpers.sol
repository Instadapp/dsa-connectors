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
		0xCe162CbD45C8Ca7646C9B641D17B154D85924a09;
}
