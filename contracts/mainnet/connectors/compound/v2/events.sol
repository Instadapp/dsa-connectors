//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogWithdraw(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogBorrow(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogPaybackOnBehalf(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        address indexed borrower,
        uint256 getId,
        uint256 setId
    );

    event LogPayback(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogDepositCToken(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 cTokenAmt,
        uint256 getId, 
        uint256 setId
    );

    event LogWithdrawCToken(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 cTokenAmt,
        uint256 getId,
        uint256 setId
    );
}
