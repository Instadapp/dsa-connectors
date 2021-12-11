pragma solidity ^0.7.0;

contract Events {

    event LogDeposit(
        address indexed universeVault,
        uint256 amountA,
        uint256 amountB,
        uint256 share0,
        uint256 share1
    );

    event LogWithdraw(
        address indexed universeVault,
        uint256 amountA,
        uint256 amountB,
        uint256 share0,
        uint256 share1
    );
}
