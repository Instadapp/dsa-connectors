//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
    event LogClaimed(
        address user,
        address token,
        uint256 amt,
        uint256 setId
    );
}
