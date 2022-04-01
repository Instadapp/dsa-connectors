//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { instaLiteInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	instaLiteInterface internal constant instaLite =
		instaLiteInterface(0xc383a3833A87009fD9597F8184979AF5eDFad019);
}
