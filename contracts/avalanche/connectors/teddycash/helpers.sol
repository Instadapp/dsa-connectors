pragma solidity ^0.7.6;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";

import { TokenInterface } from "../../common/interfaces.sol";

import {
    BorrowerOperationsLike,
    TroveManagerLike,
    StabilityPoolLike,
    StakingLike,
    CollateralSurplusLike,
    TeddyTokenLike
} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {

    BorrowerOperationsLike internal constant borrowerOperations = BorrowerOperationsLike(0xF582CAE047853cbe7F0Bc8f8321bEF4a1eBE0307);
    TroveManagerLike internal constant troveManager = TroveManagerLike(0xd22b04395705144Fd12AfFD854248427A2776194);
    StabilityPoolLike internal constant stabilityPool = StabilityPoolLike(0x7AEd63385C03Dc8ed2133F705bbB63E8EA607522);
    StakingLike internal constant staking = StakingLike(0xb4387D93B5A9392f64963cd44389e7D9D2E1053c);
    CollateralSurplusLike internal constant collateralSurplus = CollateralSurplusLike(0xBC6C16283c1260CE5CF72C951b4D399E81FBcA36);
    TeddyTokenLike internal constant teddyToken = TeddyTokenLike(0x094bd7B2D99711A1486FB94d4395801C6d0fdDcC);
    TokenInterface internal constant tsdToken = TokenInterface(0x4fbf0429599460D327BD5F55625E30E4fC066095);
    
    // Prevents stack-too-deep error
    struct AdjustTrove {
        uint maxFeePercentage;
        uint withdrawAmount;
        uint depositAmount;
        uint tsdChange;
        bool isBorrow;
    }

}
