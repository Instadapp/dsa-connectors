pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title G-UNI Staking.
 * @dev Stake G-UNI for earning rewards.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { IStakingRewards, IStakingRewardsFactory } from "./interface.sol";

contract Main is Helpers, Events {

  /**
    * @dev Deposit ERC20.
    * @notice Deposit Tokens to staking pool.
    * @param stakingToken staking token address.
    * @param amt staking token amount.
    * @param getId ID to retrieve amount.
    * @param setId ID stores the amount of staked tokens.
  */
  function deposit(
    address stakingToken,
    uint amt,
    uint getId,
    uint setId
  ) external payable returns (string memory _eventName, bytes memory _eventParam) {
    uint _amt = getUint(getId, amt);
    
    IStakingRewards stakingContract = IStakingRewards(getStakingContract(stakingToken));
    TokenInterface stakingTokenContract = TokenInterface(stakingToken);

    _amt = _amt == uint(-1) ? stakingTokenContract.balanceOf(address(this)) : _amt;

    approve(stakingTokenContract, address(stakingContract), _amt);
    stakingContract.stake(_amt);

    setUint(setId, _amt);
    _eventName = "LogDeposit(address,uint256,uint256,uint256)";
    _eventParam = abi.encode(address(stakingToken), _amt, getId, setId);
  }

  /**
    * @dev Withdraw ERC20.
    * @notice Withdraw Tokens from the staking pool.
    * @param stakingToken staking token address.
    * @param amt staking token amount.
    * @param getId ID to retrieve amount.
    * @param setIdAmount ID stores the amount of stake tokens withdrawn.
    * @param setIdReward ID stores the amount of reward tokens claimed.
  */
  function withdraw(
    address stakingToken,
    uint amt,
    uint getId,
    uint setIdAmount,
    uint setIdReward
  ) external payable returns (string memory _eventName, bytes memory _eventParam) {
    uint _amt = getUint(getId, amt);

    IStakingRewards stakingContract = IStakingRewards(getStakingContract(stakingToken));

    _amt = _amt == uint(-1) ? stakingContract.balanceOf(address(this)) : _amt;
    uint intialBal = rewardToken.balanceOf(address(this));
    stakingContract.withdraw(_amt);
    stakingContract.getReward();

    uint rewardAmt = sub(rewardToken.balanceOf(address(this)), intialBal);

    setUint(setIdAmount, _amt);
    setUint(setIdReward, rewardAmt);
    {
    _eventName = "LogWithdrawAndClaimedReward(address,uint256,uint256,uint256,uint256,uint256)";
    _eventParam = abi.encode(address(stakingToken), _amt, rewardAmt, getId, setIdAmount, setIdReward);
    }
  }

  /**
    * @dev Claim Reward.
    * @notice Claim Pending Rewards of tokens staked.
    * @param stakingToken staking token address.
    * @param setId ID stores the amount of reward tokens claimed.
  */
  function claimReward(
    address stakingToken,
    uint setId
  ) external payable returns (string memory _eventName, bytes memory _eventParam) {
    IStakingRewards stakingContract = IStakingRewards(getStakingContract(stakingToken));

    uint intialBal = rewardToken.balanceOf(address(this));
    stakingContract.getReward();
    uint finalBal = rewardToken.balanceOf(address(this));

    uint rewardAmt = sub(finalBal, intialBal);

    setUint(setId, rewardAmt);
    _eventName = "LogClaimedReward(address,uint256,uint256)";
    _eventParam = abi.encode(address(rewardToken), rewardAmt, setId);
  }

}

contract connectV2StakeGUNI is Main {
    string public constant name = "Stake-G-UNI-v1.0";
}