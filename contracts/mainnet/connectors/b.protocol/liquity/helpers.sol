pragma solidity ^0.7.6;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";

import { TokenInterface } from "../../../common/interfaces.sol";

import {
    StabilityPoolLike,
    BAMMLike
} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    StabilityPoolLike internal constant stabilityPool = StabilityPoolLike(0x66017D22b0f8556afDd19FC67041899Eb65a21bb);
    TokenInterface internal constant lqtyToken = TokenInterface(0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D);
    TokenInterface internal constant lusdToken = TokenInterface(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);    
    BAMMLike internal constant BAMM = BAMMLike(0x0d3AbAA7E088C2c82f54B2f47613DA438ea8C598);
}