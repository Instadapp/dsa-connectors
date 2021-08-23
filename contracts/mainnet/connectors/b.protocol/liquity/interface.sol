pragma solidity ^0.7.6;

interface StabilityPoolLike {
    function provideToSP(uint _amount, address _frontEndTag) external;
    function withdrawFromSP(uint _amount) external;
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;
    function getDepositorETHGain(address _depositor) external view returns (uint);
    function getDepositorLQTYGain(address _depositor) external view returns (uint);
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint);
}

interface BAMMLike {
    function deposit(uint lusdAmount) external;
    function withdraw(uint numShares) external;
    function balanceOf(address a) external view returns(uint);
    function totalSupply() external view returns(uint);
}