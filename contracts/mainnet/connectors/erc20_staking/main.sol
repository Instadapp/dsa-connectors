pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Token Staking.
 * @dev Stake ERC20 for earning rewards.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { IStakingRewards, StakingERC20Mapping } from "./interface.sol";

contract Main is Helpers, Events {

  /**
    * @dev Deposit ERC20.
    * @notice Deposit Tokens to staking pool.
    * @param stakingPoolName staking pool name.
    * @param amt staking token amount.
    * @param getId ID to retrieve amount.
    * @param setId ID stores the amount of staked tokens.
  */
  function deposit(
    string calldata stakingPoolName,
    uint amt,
    uint getId,
    uint setId
  ) external payable returns (string memory _eventName, bytes memory _eventParam) {
    uint _amt = getUint(getId, amt);
    (
      IStakingRewards stakingContract,
      TokenInterface stakingToken,
      ,
      bytes32 stakingType
    ) = getStakingData(stakingPoolName);

    _amt = _amt == uint(-1) ? stakingToken.balanceOf(address(this)) : _amt;

    approve(stakingToken, address(stakingContract), _amt);
    stakingContract.stake(_amt);

    setUint(setId, _amt);
    _eventName = "LogDeposit(address,bytes32,uint256,uint256,uint256)";
    _eventParam = abi.encode(address(stakingToken), stakingType, _amt, getId, setId);
  }

  /**
    * @dev Withdraw ERC20.
    * @notice Withdraw Tokens from the staking pool.
    * @param stakingPoolName staking pool name.
    * @param amt staking token amount.
    * @param getId ID to retrieve amount.
    * @param setIdAmount ID stores the amount of stake tokens withdrawn.
    * @param setIdReward ID stores the amount of reward tokens claimed.
  */
  function withdraw(
    string calldata stakingPoolName,
    uint amt,
    uint getId,
    uint setIdAmount,
    uint setIdReward
  ) external payable returns (string memory _eventName, bytes memory _eventParam) {
    uint _amt = getUint(getId, amt);
    (
      IStakingRewards stakingContract,
      TokenInterface stakingToken,
      TokenInterface rewardToken,
      bytes32 stakingType
    ) = getStakingData(stakingPoolName);

    _amt = _amt == uint(-1) ? stakingContract.balanceOf(address(this)) : _amt;
    uint intialBal = rewardToken.balanceOf(address(this));
    stakingContract.withdraw(_amt);
    stakingContract.getReward();

    uint rewardAmt = sub(rewardToken.balanceOf(address(this)), intialBal);

    setUint(setIdAmount, _amt);
    setUint(setIdReward, rewardAmt);
    {
    _eventName = "LogWithdrawAndClaimedReward(address,bytes32,uint256,uint256,uint256,uint256,uint256)";
    _eventParam = abi.encode(address(stakingToken), stakingType, _amt, rewardAmt, getId, setIdAmount, setIdReward);
    }
  }

  /**
    * @dev Claim Reward.
    * @notice Claim Pending Rewards of tokens staked.
    * @param stakingPoolName staking pool name.
    * @param setId ID stores the amount of reward tokens claimed.
  */
  function claimReward(
    string calldata stakingPoolName,
    uint setId
  ) external payable returns (string memory _eventName, bytes memory _eventParam) {
     (
      IStakingRewards stakingContract,
      ,
      TokenInterface rewardToken,
      bytes32 stakingType
    ) = getStakingData(stakingPoolName);

    uint intialBal = rewardToken.balanceOf(address(this));
    stakingContract.getReward();
    uint finalBal = rewardToken.balanceOf(address(this));

    uint rewardAmt = sub(finalBal, intialBal);

    setUint(setId, rewardAmt);
    _eventName = "LogClaimedReward(address,bytes32,uint256,uint256)";
    _eventParam = abi.encode(address(rewardToken), stakingType, rewardAmt, setId);
  }

}

contract connectV2StakeERC20 is Main {
    string public constant name = "Stake-ERC20-v1.0";
}