pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { IStakingRewards, StakingERC20Mapping } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {

  /**
   * @dev Convert String to bytes32.
   */
  function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
    require(bytes(str).length != 0, "string-empty");
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      result := mload(add(str, 32))
    }
  }

  /**
   * @dev Get staking data
   */
  function getStakingData(string memory stakingName)
  internal
  view
  returns (
    IStakingRewards stakingContract,
    TokenInterface stakingToken,
    TokenInterface rewardToken,
    bytes32 stakingType
  )
  {
    stakingType = stringToBytes32(stakingName);
    StakingERC20Mapping.StakingData memory stakingData = StakingERC20Mapping(getMappingAddr()).stakingMapping(stakingType);
    require(stakingData.stakingPool != address(0) && stakingData.stakingToken != address(0), "Wrong Staking Name");
    stakingContract = IStakingRewards(stakingData.stakingPool);
    stakingToken = TokenInterface(stakingData.stakingToken);
    rewardToken = TokenInterface(stakingData.rewardToken);
  }

  function getMappingAddr() internal virtual view returns (address) {
    return 0xbE658233bA9990d86155b3902fd05a7AfC7eBdB5; // InstaMapping Address
  }

}