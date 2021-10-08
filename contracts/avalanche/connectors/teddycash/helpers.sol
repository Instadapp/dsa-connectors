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
    LqtyTokenLike
} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {

    BorrowerOperationsLike internal constant borrowerOperations = BorrowerOperationsLike(0x24179CD81c9e782A4096035f7eC97fB8B783e007);
    TroveManagerLike internal constant troveManager = TroveManagerLike(0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4bb2);
    StabilityPoolLike internal constant stabilityPool = StabilityPoolLike(0x66017D22b0f8556afDd19FC67041899Eb65a21bb);
    StakingLike internal constant staking = StakingLike(0x4f9Fbb3f1E99B56e0Fe2892e623Ed36A76Fc605d);
    CollateralSurplusLike internal constant collateralSurplus = CollateralSurplusLike(0x3D32e8b97Ed5881324241Cf03b2DA5E2EBcE5521);
    LqtyTokenLike internal constant lqtyToken = LqtyTokenLike(0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D);
    TokenInterface internal constant lusdToken = TokenInterface(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);
    
    // Prevents stack-too-deep error
    struct AdjustTrove {
        uint maxFeePercentage;
        uint withdrawAmount;
        uint depositAmount;
        uint lusdChange;
        bool isBorrow;
    }

}
