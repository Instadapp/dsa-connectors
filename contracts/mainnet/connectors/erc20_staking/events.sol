pragma solidity ^0.7.0;

contract Events {

  event LogDeposit(
    address indexed stakingToken,
    bytes32 indexed stakingType,
    uint256 amount,
    uint getId,
    uint setId
  );

  event LogWithdraw(
    address indexed stakingToken,
    bytes32 indexed stakingType,
    uint256 amount,
    uint getId,
    uint setId
  );

  event LogClaimedReward(
    address indexed rewardToken,
    bytes32 indexed stakingType,
    uint256 rewardAmt,
    uint setId
  );

}