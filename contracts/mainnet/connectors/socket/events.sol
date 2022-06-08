//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
    event LogSocketBridge (
        bytes txData,
        address token,
        uint256 amount,
        uint256 getId
    );
}