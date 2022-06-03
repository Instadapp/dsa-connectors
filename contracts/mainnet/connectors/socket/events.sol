//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
    event LogBridge (
        address to,
        bytes txData,
        address token,
        uint256 allowanceTarget,
        uint256 amount,
        uint256 getId
    );
}