//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {

    event LogDeposit(
        uint256 subaccount,
        address token,
        uint256 amount,
        bool enableCollateral,
        uint256 getId,
        uint256 setId
    );

    event LogWithdraw(
        uint256 subaccount,
        address token,
        uint256 amount,
        uint256 getId,
        uint256 setId
    );

    event LogBorrow(
        uint256 subAccount,
        address token,
        uint256 amount,
        uint256 getId,
        uint256 setId
    );

    event LogRepay(
        uint256 subAccount,
        address token,
        uint256 amount,
        uint256 getId,
        uint256 setId
    );

    event LogMint(
        uint256 subAccount,
        address token,
        uint256 amount,
        uint256 getId,
        uint256 setId
    );

    event LogBurn(
        uint256 subAccount,
        address token,
        uint256 amount,
        uint256 getId,
        uint256 setId
    );

    event LogETransfer(
        uint256 subAccount1,
        uint256 subAccount2,
        address token,
        uint256 amount,
        uint256 getId,
        uint256 setId
    );

    event LogDTransfer(
        uint256 subAccount1,
        uint256 subAccount2,
        address token,
        uint256 amount,
        uint256 getId,
        uint256 setId
    );
}
