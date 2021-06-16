pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { IStakingRewards, IStakingRewardsFactory, IGUniPoolResolver } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {

  IGUniPoolResolver constant internal guniResolver = 
    IGUniPoolResolver(0x729BF02a9A786529Fc80498f8fd0051116061B13);

  TokenInterface constant internal rewardToken = TokenInterface(0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb);

  function getStakingContract(address stakingToken) internal view returns (address) {
    IStakingRewardsFactory.StakingRewardsInfo memory stakingRewardsInfo =
      guniResolver.getStakingFactory().stakingRewardsInfoByStakingToken(stakingToken);

    return stakingRewardsInfo.stakingRewards;
  }

}