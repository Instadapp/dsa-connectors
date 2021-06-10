pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { IStakingRewards, SynthetixMapping } from "./interface.sol";

contract Main {

  /**
    * @dev Deposit Token.
    * @param stakingPoolName staking token address.
    * @param amt staking token amount.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function deposit(
    string calldata stakingPoolName,
    uint amt,
    uint getId,
    uint setId
  ) external payable {
    uint _amt = getUint(getId, amt);
    (
      IStakingRewards stakingContract,
      TokenInterface stakingToken,
      ,
      bytes32 stakingType
    ) = getStakingData(stakingPoolName);

    _amt = _amt == uint(-1) ? stakingToken.balanceOf(address(this)) : _amt;

    stakingToken.approve(address(stakingContract), _amt);
    stakingContract.stake(_amt);

    setUint(setId, _amt);
    emit LogDeposit(address(stakingToken), stakingType, _amt, getId, setId);
  }

  /**
    * @dev Withdraw Token.
    * @param stakingPoolName staking token address.
    * @param amt staking token amount.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setIdAmount Set token amount at this ID in `InstaMemory` Contract.
    * @param setIdReward Set reward amount at this ID in `InstaMemory` Contract.
  */
  function withdraw(
    string calldata stakingPoolName,
    uint amt,
    uint getId,
    uint setIdAmount,
    uint setIdReward
  ) external payable {
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
    uint finalBal = rewardToken.balanceOf(address(this));

    uint rewardAmt = sub(finalBal, intialBal);

    setUint(setIdAmount, _amt);
    setUint(setIdReward, rewardAmt);

    emit LogWithdraw(address(stakingToken), stakingType, _amt, getId, setIdAmount);

    emit LogClaimedReward(address(rewardToken), stakingType, rewardAmt, setIdReward);
  }

  /**
    * @dev Claim Reward.
    * @param stakingPoolName staking token address.
    * @param setId Set reward amount at this ID in `InstaMemory` Contract.
  */
  function claimReward(
    string calldata stakingPoolName,
    uint setId
  ) external payable {
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
    emit LogClaimedReward(address(rewardToken), stakingType, rewardAmt, setId);
  }

}