//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import {  CometRewards } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	CometRewards internal constant cometRewards =
		CometRewards(0x123964802e6ABabBE1Bc9547D72Ef1B69B00A6b1);
}
