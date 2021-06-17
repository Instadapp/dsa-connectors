pragma solidity ^0.7.0;

contract Events {

  event LogDeposit(
    address indexed stakingToken,
    bytes32 indexed stakingType,
    uint256 amount,
    uint getId,
    uint setId
  );

  event LogWithdrawAndClaimedReward(
    address indexed stakingToken,
    bytes32 indexed stakingType,
    uint256 amount,
    uint256 rewardAmt,
    uint getId,
    uint setIdAmount,
    uint setIdReward
  );

  event LogClaimedReward(
    address indexed rewardToken,
    bytes32 indexed stakingType,
    uint256 rewardAmt,
    uint setId
  );

}