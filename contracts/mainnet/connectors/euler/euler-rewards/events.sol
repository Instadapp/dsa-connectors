//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
    event LogClaimed(
        address user,
        address token,
        uint256 amt,
        bytes32[] proof,
        uint256 getId,
        uint256 setId
    );
}
