pragma solidity ^0.7.0;

contract Events {

  event LogDeposit(
    address indexed stakingPool,
    uint256 amount,
    uint getId,
    uint setId
  );

  event LogWithdrawAndClaimedReward(
    address indexed stakingPool,
    uint256 amount,
    uint256 rewardAmt,
    uint getId,
    uint setIdAmount,
    uint setIdReward
  );

  event LogClaimedReward(
    address indexed stakingPool,
    address indexed rewardToken,
    uint256 rewardAmt,
    uint setId
  );

}