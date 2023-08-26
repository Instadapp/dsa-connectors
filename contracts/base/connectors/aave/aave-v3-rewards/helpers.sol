//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { AaveIncentivesInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	/**
	 * @dev Aave v3 Incentives
	 */
	AaveIncentivesInterface internal constant incentives =
		AaveIncentivesInterface(0xf9cc4F0D883F1a1eb2c253bdb46c254Ca51E1F44);
}
