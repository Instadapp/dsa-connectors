pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IStakingRewards {
  function stake(uint256 amount) external;
  function withdraw(uint256 amount) external;
  function getReward() external;
  function balanceOf(address) external view returns(uint);
}

interface IStakingRewardsFactory {

  struct StakingRewardsInfo {
    address stakingRewards;
    uint rewardAmount;
  }

  function stakingRewardsInfoByStakingToken(address) external view returns(StakingRewardsInfo memory);

}

interface IGUniPoolResolver {

  function getStakingFactory() external view returns(IStakingRewardsFactory);

}