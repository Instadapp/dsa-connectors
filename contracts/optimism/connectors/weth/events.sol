pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdraw(uint256 tokenAmt, uint256 getId, uint256 setId);
}
