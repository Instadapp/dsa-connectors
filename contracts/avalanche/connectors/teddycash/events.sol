pragma solidity ^0.7.6;

contract Events {

    /* Trove */
    event LogOpen(
        address indexed borrower,
        uint maxFeePercentage,
        uint depositAmount,
        uint borrowAmount,
        uint256[] getIds,
        uint256[] setIds
    );
    event LogClose(address indexed borrower, uint setId);
    event LogDeposit(address indexed borrower, uint amount, uint getId, uint setId);
    event LogWithdraw(address indexed borrower, uint amount, uint getId, uint setId);
    event LogBorrow(address indexed borrower, uint amount, uint getId, uint setId);
    event LogRepay(address indexed borrower, uint amount, uint getId, uint setId);
    event LogAdjust(
        address indexed borrower,
        uint maxFeePercentage,
        uint depositAmount,
        uint withdrawAmount,
        uint borrowAmount,
        uint repayAmount,
        uint256[] getIds,
        uint256[] setIds
    );
    event LogClaimCollateralFromRedemption(address indexed borrower, uint amount, uint setId);

    /* Stability Pool */
    event LogStabilityDeposit(
        address indexed borrower,
        uint amount,
        uint avaxGain,
        uint teddyGain,
        address frontendTag,
        uint getDepositId,
        uint setDepositId,
        uint setAvaxGainId,
        uint setTeddyGainId
    );
    event LogStabilityWithdraw(address indexed borrower,
        uint amount,
        uint avaxGain,
        uint teddyGain,
        uint getWithdrawId,
        uint setWithdrawId,
        uint setAvaxGainId,
        uint setTeddyGainId
    );
    event LogStabilityMoveEthGainToTrove(address indexed borrower, uint amount);

    /* Staking */
    event LogStake(address indexed borrower, uint amount, uint getStakeId, uint setStakeId, uint setAvaxGainId, uint setTsdGainId);
    event LogUnstake(address indexed borrower, uint amount, uint getUnstakeId, uint setUnstakeId, uint setAvaxGainId, uint setTsdGainId);
    event LogClaimStakingGains(address indexed borrower, uint avaxGain, uint tsdGain, uint setAvaxGainId, uint setTsdGainId);
}
