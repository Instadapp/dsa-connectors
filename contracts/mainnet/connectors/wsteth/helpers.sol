//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import './interface.sol';
import { TokenInterface } from "../../common/interfaces.sol";

abstract contract Helpers {
    IWSTETH internal constant wstethContract = IWSTETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    TokenInterface internal constant  stethContract = TokenInterface(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
}
