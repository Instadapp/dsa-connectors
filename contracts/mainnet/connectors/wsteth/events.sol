//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(uint256 stethAmt, uint256 wstethAmt, uint256 getId, uint256 setId);
    event LogWithdraw(uint256 wstethAmt, uint256 stethAmt, uint256 getId, uint256 setId);
}
