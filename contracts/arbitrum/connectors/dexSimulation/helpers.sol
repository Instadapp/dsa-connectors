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
		0xa5044f8FfA8FbDdd0781cEDe502F1C493BB6978A;
}
