pragma solidity ^0.7.0;
pragma abicoder v2;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { IERC20, IMiniChefV2, IStakingRewards } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {

    /**
     * @dev Pangolin MiniChefV2
     */
    IMiniChefV2 internal constant minichefv2 = IMiniChefV2(0x1f806f7C8dED893fd3caE279191ad7Aa3798E928);

    /**
     * @dev Pangolin Token
     */
    IERC20 internal constant PNG = IERC20(0x60781C2586D68229fde47564546784ab3fACA982);

    // LP Staking, use minichefv2 to staking lp tokens and earn png
    function _depositLPStake(
        uint pid,
        uint amount
    ) internal returns (address lpTokenAddr) {
        require(pid < minichefv2.poolLength(), "Invalid pid!");
        IERC20 lptoken = minichefv2.lpToken(pid);

        require(amount > 0, "Invalid amount, amount cannot be 0");
        require(lptoken.balanceOf(address(this)) > 0, "Invalid LP token balance");
        require(lptoken.balanceOf(address(this)) >= amount, "Invalid amount, amount greater than balance of LP token");

        approve(
            lptoken, 
            address(minichefv2), 
            amount
        );

        minichefv2.deposit(pid, amount, address(this));
        lpTokenAddr = address(lptoken);
    }

    function _withdraw_LP_Stake(
        uint pid,
        uint amount
    ) internal returns (address lpTokenAddr) {
        require(pid < minichefv2.poolLength(), "Invalid pid!");
        
        IMiniChefV2.UserInfo memory userinfo = minichefv2.userInfo(pid, address(this));

        require(userinfo.amount >= amount, "Invalid amount, amount greater than balance of staking");
        require(amount > 0, "Invalid amount, amount cannot be 0");

        minichefv2.withdraw(pid, amount, address(this));

        IERC20 lptoken = minichefv2.lpToken(pid);
        lpTokenAddr = address(lptoken);
    }

    function _withdraw_and_getRewards_LP_Stake(
        uint pid,
        uint amount
    ) internal returns (uint256 rewardAmount, address lpTokenAddr) {
        require(pid < minichefv2.poolLength(), "Invalid pid!");

        IMiniChefV2.UserInfo memory userinfo = minichefv2.userInfo(pid, address(this));

        require(userinfo.amount >=  amount, "Invalid amount, amount greater than balance of staking");
        require(amount > 0, "Invalid amount, amount cannot be 0");

        rewardAmount = minichefv2.pendingReward(pid, address(this));

        minichefv2.withdrawAndHarvest(pid, amount, address(this));

        IERC20 lptoken = minichefv2.lpToken(pid);
        lpTokenAddr = address(lptoken);
    }

    function _getLPStakeReward(
        uint pid
    ) internal returns (uint256 rewardAmount, address lpTokenAddr) {
        require(pid < minichefv2.poolLength(), "Invalid pid!");

        rewardAmount = minichefv2.pendingReward(pid, address(this));

        require(rewardAmount > 0, "No rewards to claim");

        minichefv2.harvest(pid, address(this));

        IERC20 lptoken = minichefv2.lpToken(pid);
        lpTokenAddr = address(lptoken);
    }

    function _emergencyWithdraw_LP_Stake(
        uint pid
    ) internal returns (uint256 lpAmount, address lpTokenAddr) {
        require(pid < minichefv2.poolLength(), "Invalid pid!");

        IMiniChefV2.UserInfo memory userinfo = minichefv2.userInfo(pid, address(this));
        lpAmount = userinfo.amount;

        minichefv2.emergencyWithdraw(pid, address(this));
        IERC20 lptoken = minichefv2.lpToken(pid);
        lpTokenAddr = address(lptoken);
    }

    // PNG Staking (Stake PNG, earn another token)
    function _depositPNGStake(
        address stakingContract_addr,
        uint amount
    ) internal {
        IStakingRewards stakingContract = IStakingRewards(stakingContract_addr);

        require(amount > 0, "Invalid amount, amount cannot be 0");
        require(PNG.balanceOf(address(this)) > 0, "Invalid PNG balance");
        require(PNG.balanceOf(address(this)) >=  amount, "Invalid amount, amount greater than balance of PNG");

        approve(PNG, stakingContract_addr, amount);

        stakingContract.stake(amount);
    }

    function _withdrawPNGStake(
        address stakingContract_addr,
        uint amount
    ) internal {
        IStakingRewards stakingContract = IStakingRewards(stakingContract_addr);

        require(stakingContract.balanceOf(address(this)) >=  amount, "Invalid amount, amount greater than balance of staking");
        require(amount > 0, "Invalid amount, amount cannot be 0");

        stakingContract.withdraw(amount);
    }

    function _exitPNGStake(
        address stakingContract_addr
    ) internal returns (uint256 exitAmount, uint256 rewardAmount, address rewardToken){
        IStakingRewards stakingContract = IStakingRewards(stakingContract_addr);

        exitAmount = stakingContract.balanceOf(address(this));
        rewardAmount = stakingContract.rewards(address(this));

        require(exitAmount > 0, "No balance to exit");

        stakingContract.exit();
    }

    function _claimPNGStakeReward(
        address stakingContract_addr
    ) internal returns (uint256 rewardAmount, address rewardToken) {
        IStakingRewards stakingContract = IStakingRewards(stakingContract_addr);

        rewardAmount = stakingContract.rewards(address(this));
        rewardToken = stakingContract.rewardsToken();

        require(rewardAmount > 0, "No rewards to claim");

        stakingContract.getReward();
    }
}
