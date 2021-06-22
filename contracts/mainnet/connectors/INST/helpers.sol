pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { InstaTokenInterface, InstaGovernorInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev InstaGovernorBravo
     */
    InstaGovernorInterface internal constant instaGovernor = InstaGovernorInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    /**
     * @dev INST Token
     */
    InstaTokenInterface internal constant instToken = InstaTokenInterface(0xc00e94Cb662C3520282E6f5717214004A7f26888);
}