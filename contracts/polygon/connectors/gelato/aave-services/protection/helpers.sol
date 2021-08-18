// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {LendingPoolInterface, AaveServicesInterface} from "./interface.sol";

abstract contract Helpers {
    // solhint-disable-next-line const-name-snakecase
    LendingPoolInterface internal constant _lendingPool =
        LendingPoolInterface(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);

    // solhint-disable-next-line const-name-snakecase
    AaveServicesInterface internal constant _aaveServices =
        AaveServicesInterface(0x18FAbC997fDd624764E1974b283B1b904b66d613);

    // solhint-disable-next-line const-name-snakecase
    address internal constant _protectionAction =
        0xc38b6dbd0F84777AA4fae2d36FE1506428A22b9B;
}
