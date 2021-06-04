pragma solidity ^0.7.6;

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
    event LogClaimCollateralFromRedemption(address indexed borrower, uint amount, uint setId);

    /* Stability Pool */
    event LogStabilityDeposit(
        address indexed borrower,
        uint amount,
        address frontendTag,
        uint getDepositId,
        uint setEthGainId,
        uint setLqtyGainId
    );
    event LogStabilityWithdraw(address indexed borrower,
        uint amount,
        uint setWithdrawId,
        uint setEthGainId,
        uint setLqtyGainId
    );
    event LogStabilityMoveEthGainToTrove(address indexed borrower, uint amount);

    /* Staking */
    event LogStake(address indexed borrower, uint amount, uint getStakeId, uint setEthGainId, uint setLusdGainId);
    event LogUnstake(address indexed borrower, uint amount, uint setUnstakeId, uint setEthGainId, uint setLusdGainId);
    event LogClaimStakingGains(address indexed borrower, uint ethGain, uint lusdGain, uint setEthGainId, uint setLusdGainId);
}
