//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { TokenInterface}  from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	/**
	 * @dev uniswap v3 Swap Router
	 */
	ISwapRouter constant swapRouter =
		ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
}