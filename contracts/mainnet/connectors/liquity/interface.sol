pragma solidity ^0.7.6;

interface BorrowerOperationsLike {
    function openTrove(
        uint256 _maxFee,
        uint256 _LUSDAmount,
        address _upperHint,
        address _lowerHint
    ) external payable;

    function addColl(address _upperHint, address _lowerHint) external payable;

    function withdrawColl(
        uint256 _amount,
        address _upperHint,
        address _lowerHint
    ) external;

    function withdrawLUSD(
        uint256 _maxFee,
        uint256 _amount,
        address _upperHint,
        address _lowerHint
    ) external;

    function repayLUSD(
        uint256 _amount,
        address _upperHint,
        address _lowerHint
    ) external;

    function closeTrove() external;

    function adjustTrove(
        uint256 _maxFee,
        uint256 _collWithdrawal,
        uint256 _debtChange,
        bool isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external payable;

    function claimCollateral() external;
}

interface TroveManagerLike {
    function getTroveColl(address _borrower) external view returns (uint);
    function getTroveDebt(address _borrower) external view returns (uint);
}

interface StabilityPoolLike {
    function provideToSP(uint _amount, address _frontEndTag) external;
    function withdrawFromSP(uint _amount) external;
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;
    function getDepositorETHGain(address _depositor) external view returns (uint);
    function getDepositorLQTYGain(address _depositor) external view returns (uint);
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint);
}

interface StakingLike {
    function stake(uint _LQTYamount) external;
    function unstake(uint _LQTYamount) external;
    function getPendingETHGain(address _user) external view returns (uint);
    function getPendingLUSDGain(address _user) external view returns (uint);
    function stakes(address owner) external view returns (uint);
}

interface CollateralSurplusLike { 
    function getCollateral(address _account) external view returns (uint);
}

interface LqtyTokenLike {
    function balanceOf(address account) external view returns (uint256);
}
