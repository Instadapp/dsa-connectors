pragma solidity ^0.7.0;

contract Events {

  event LogDeposit(
    address indexed stakingToken,
    uint256 amount,
    uint getId,
    uint setId
  );

  event LogWithdrawAndClaimedReward(
    address indexed stakingToken,
    uint256 amount,
    uint256 rewardAmt,
    uint getId,
    uint setIdAmount,
    uint setIdReward
  );

  event LogClaimedReward(
    address indexed rewardToken,
    uint256 rewardAmt,
    uint setId
  );

}