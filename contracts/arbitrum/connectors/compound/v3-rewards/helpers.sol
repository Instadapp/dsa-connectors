//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import {  CometRewards } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	CometRewards internal constant cometRewards =
		CometRewards(0x88730d254A2f7e6AC8388c3198aFd694bA9f7fae);
}
