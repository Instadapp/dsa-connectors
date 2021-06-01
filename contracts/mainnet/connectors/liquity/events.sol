pragma solidity ^0.7.0;

contract Events {

    /* Trove */
    event LogOpen(
        address indexed borrower,
        uint maxFeePercentage,
        uint depositAmount,
        uint borrowAmount,
        uint getId,
        uint setId
    );
    event LogClose(address indexed borrower, uint setId);
    event LogDeposit(address indexed borrower, uint amount, uint getId);
    event LogWithdraw(address indexed borrower, uint amount, uint setId);
    event LogBorrow(address indexed borrower, uint amount, uint setId);
    event LogRepay(address indexed borrower, uint amount, uint getId);
    event LogAdjust(
        address indexed borrower,
        uint maxFeePercentage,
        uint depositAmount,
        uint withdrawAmount,
        uint borrowAmount,
        uint repayAmount,
        uint getDepositId,
        uint setWithdrawId,
        uint getRepayId,
        uint setBorrowId
    );
    event LogClaimCollateralFromRedemption(address indexed borrower);

    /* Stability Pool */
    event LogStabilityDeposit(address indexed borrower, uint amount, address frontendTag, uint getId);
    event LogStabilityWithdraw(address indexed borrower, uint amount, uint setId);
    event LogStabilityMoveEthGainToTrove(address indexed borrower);

    /* Staking */
    event LogStake(address indexed borrower, uint amount, uint getId);
    event LogUnstake(address indexed borrower, uint amount, uint setId);
    event LogClaimGains(address indexed borrower);
}