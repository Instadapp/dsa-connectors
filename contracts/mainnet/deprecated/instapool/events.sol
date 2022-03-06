//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
    event LogDepositLiquidity(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdrawLiquidity(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogFlashBorrow(
        address indexed token,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogFlashPayback(
        address indexed token,
        uint256 tokenAmt,
        uint256 feeCollected,
        uint256 getId,
        uint256 setId
    );

    event LogFlashPaybackOrigin(
        address indexed origin,
        address indexed token,
        uint256 tokenAmt,
        uint256 feeCollected,
        uint256 originFeeAmt,
        uint256 getId,
        uint256 setId
    );

    event LogMultiBorrow(
        address[] tokens,
        uint256[] amts,
        uint256[] getId,
        uint256[] setId
    );

    event LogMultiPayback(
        address[] tokens,
        uint256[] getId,
        uint256[] setId
    );

    event LogMultiPaybackOrigin(
        address indexed origin,
        address[] tokens,
        // uint256[] amts,
        // uint256[] feeCollected,
        // uint256[] originFeeAmt,
        uint256[] getId,
        uint256[] setId
    );
}
