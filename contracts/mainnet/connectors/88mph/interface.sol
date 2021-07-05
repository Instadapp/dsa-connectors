pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IDInterest {
    function deposit(uint256 amount, uint256 maturationTimestamp) external;

    function withdraw(uint256 depositID, uint256 fundingID) external;

    function earlyWithdraw(uint256 depositID, uint256 fundingID) external;
}

interface IVesting {
    function vest(
        address to,
        uint256 amount,
        uint256 vestPeriodInSeconds
    ) external returns (uint256 vestIdx);

    function withdrawVested(address account, uint256 vestIdx)
        external
        returns (uint256 withdrawnAmount);
}
