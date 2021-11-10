// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;

contract Events {
    event LogDeposit(
        address indexed token,
        uint256 amount,
        uint256 getId,
        uint256 setId
    );

    event LogWithdraw(
        address indexed token,
        uint256 amount,
        uint256 getId,
        uint256 setId
    );

    event LogBorrow(
        address indexed token,
        uint256 amount,
        uint256 indexed rateMode,
        uint256 getId,
        uint256 setId
    );

    event LogPayback(
        address indexed token,
        uint256 amount,
        uint256 indexed rateMode,
        uint256 getId,
        uint256 setId
    );

    event LogEnableCollateral(address[] tokens);
}
