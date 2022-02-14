// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract Events {
    event LogSubmitProtection(
        address indexed dsa,
        address indexed action,
        uint256 wantedHealthFactor,
        uint256 minimumHealthFactor,
        bool isPermanent
    );
    event LogUpdateProtection(
        address indexed dsa,
        address indexed action,
        uint256 wantedHealthFactor,
        uint256 minimumHealthFactor,
        bool isPermanent
    );
    event LogCancelProtection(address indexed dsa, address indexed action);
    event LogCancelAndRevoke(address indexed dsa, address indexed action);
}