pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(address indexed vault, uint256 shareAmt, uint256 depositAmt, uint256 getId, uint256 setId);
    event LogWithdraw(address indexed recipient, uint256 shareAmt, uint256 withdrawAmt, uint256 getId, uint256 setId);
}