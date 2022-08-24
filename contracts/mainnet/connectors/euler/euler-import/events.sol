//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {

    event LogEulerImport (
        address user,
        uint sourceId,
        uint targetId,
        address[] supplyTokens,
        address[] borrowTokens,
        bool[] enterMarket
    )
}