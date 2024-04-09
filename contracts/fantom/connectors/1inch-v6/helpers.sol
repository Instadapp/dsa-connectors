//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";

abstract contract Helpers is DSMath, Basic {
	/**
	 * @dev 1Inch Router v6 Address
	 */
	address internal constant oneInchAddr =
		0x111111125421cA6dc452d289314280a0f8842A65;
}
