// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Ubiquity Algorithmic Dollar Manager Address
     */
    address internal constant UbiquityAlgorithmicDollarManager =
        0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98;

    /**
     * @dev DAI Address
     */
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    /**
     * @dev USDC Address
     */
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    /**
     * @dev USDT Address
     */
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /**
     * @dev Curve 3CRV Token Address
     */
    address internal constant CRV3 = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    /**
     * @dev Curve 3Pool Address
     */
    address internal constant Pool3 =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
}
