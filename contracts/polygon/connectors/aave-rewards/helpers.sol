pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { AaveIncentivesInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Aave Incentives
     */
    AaveIncentivesInterface internal constant incentives = AaveIncentivesInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
}