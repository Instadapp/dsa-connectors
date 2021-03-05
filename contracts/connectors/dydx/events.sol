pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(address indexed token, uint marketId, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdraw(address indexed token, uint marketId, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogBorrow(address indexed token, uint marketId, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogPayback(address indexed token, uint marketId, uint256 tokenAmt, uint256 getId, uint256 setId);
}
