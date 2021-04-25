pragma solidity ^0.7.0;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { AaveIncentivesInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Aave Incentives
     */
    AaveIncentivesInterface internal constant incentives = AaveIncentivesInterface(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);
}
