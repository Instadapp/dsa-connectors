//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./interface.sol";

contract Variables {
    address internal constant EULER_MAINNET = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
    IEulerMarkets internal constant markets = IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);
}
