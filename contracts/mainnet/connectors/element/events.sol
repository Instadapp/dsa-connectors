pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        address indexed tranche,
        uint256 amount,
        address destination
    );

    event LogWithdrawPrincipal(
        address indexed tranche,
        uint256 amount,
        address destination
    );

    event LogWithdrawInterest(
        address indexed tranche,
        uint256 amount,
        address destination
    );
}
