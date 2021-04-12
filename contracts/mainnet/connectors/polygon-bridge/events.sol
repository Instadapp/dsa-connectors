pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        address targetDsa,
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    );
    event LogWithdraw(bytes proof);
}