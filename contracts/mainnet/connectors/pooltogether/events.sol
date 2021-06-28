pragma solidity ^0.7.0;

contract Events {
    event LogDepositTo(address to, uint256 amount, address controlledToken, address referrer);
    event LogWithdrawInstantlyFrom(address from, uint256 amount, address controlledToken, uint256 maximumExitFee);
}