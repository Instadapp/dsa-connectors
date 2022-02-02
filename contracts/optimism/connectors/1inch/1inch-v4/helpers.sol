pragma solidity ^0.7.0;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";


abstract contract Helpers is DSMath, Basic {
    /**
     * @dev 1Inch Address
     */
   address internal constant oneInchAddr = 0x1111111254760F7ab3F16433eea9304126DCd199;
}