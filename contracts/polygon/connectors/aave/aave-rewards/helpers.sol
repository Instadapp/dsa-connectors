pragma solidity ^0.7.0;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { AaveIncentivesInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Aave Incentives
     */
    AaveIncentivesInterface internal constant incentives = AaveIncentivesInterface(0x357D51124f59836DeD84c8a1730D72B749d8BC23);
}
