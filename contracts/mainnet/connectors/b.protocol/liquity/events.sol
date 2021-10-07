pragma solidity ^0.7.6;

contract Events {

    /* Stability Pool */
    event LogStabilityDeposit(
        address indexed borrower,
        uint amount,
        uint lqtyGain,
        uint getDepositId,
        uint setDepositId,
        uint setLqtyGainId
    );
    event LogStabilityWithdraw(
        address indexed borrower,
        uint numShares,
        uint lqtyGain,
        uint getWithdrawId,
        uint setWithdrawId,
        uint setLqtyGainId
    );
}