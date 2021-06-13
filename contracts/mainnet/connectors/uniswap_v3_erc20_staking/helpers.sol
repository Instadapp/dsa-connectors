pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { IStakingRewards, IStakingRewardsFactory } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {

  IStakingRewardsFactory constant internal stakingRewardsFactory = 
    IStakingRewardsFactory(address(0)); // TODO

  TokenInterface constant internal rewardToken = TokenInterface(address(0)); // TODO

  function getStakingContract(address stakingToken) internal view returns (address) {
    IStakingRewardsFactory.StakingRewardsInfo memory stakingRewardsInfo =
      stakingRewardsFactory.stakingRewardsInfoByStakingToken(stakingToken);

    return stakingRewardsInfo.stakingRewards;
  }

}