//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { DSMath } from "../../../../common/math.sol";
import { Basic } from "../../../../common/basic.sol";
import { AaveIncentivesInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	/**
	 * @dev Aave v3 Incentives
	 */
	AaveIncentivesInterface internal constant incentives =
		AaveIncentivesInterface(0x01D83Fe6A10D2f2B7AF17034343746188272cAc9);
}
