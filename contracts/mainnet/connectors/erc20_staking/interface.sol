pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IStakingRewards {
  function stake(uint256 amount) external;
  function withdraw(uint256 amount) external;
  function getReward() external;
  function balanceOf(address) external view returns(uint);
}

interface StakingERC20Mapping {

  struct StakingData {
    address stakingPool;
    address stakingToken;
    address rewardToken;
  }

  function stakingMapping(bytes32) external view returns(StakingData memory);

}