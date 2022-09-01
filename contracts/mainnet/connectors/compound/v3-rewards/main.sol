//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Compound.
 * @dev Rewards.
 */

import { TokenInterface } from "../../../common/interfaces.sol";
import { Stores } from "../../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract CompoundV3RewardsResolver is Events, Helpers {
	/**
	 * @dev Claim rewards and interests accrued in supplied/borrowed base asset.
	 * @notice Claim rewards and interests accrued.
	 * @param market The address of the market.
	 * @param account The account of which the rewards are to be claimed.
	 * @param accrue Should accrue the rewards and interest before claiming.
	 * @param setId ID stores the amount of rewards claimed.
	 */
	function claimRewards(
		address market,
		address account,
		bool accrue,
		uint256 setId
	) public returns (string memory eventName_, bytes memory eventParam_) {
		uint256 rewardsOwed = cometRewards.getRewardOwed(market, account).owed;
		cometRewards.claim(market, account, accrue);

		setUint(setId, rewardsOwed);

		eventName_ = "LogRewardsClaimed(address,address,uint256,uint256,bool)";
		eventParam_ = abi.encode(market, account, rewardsOwed, setId, accrue);
	}

	/**
	 * @dev Claim rewards and interests accrued in supplied/borrowed base asset.
	 * @notice Claim rewards and interests accrued and transfer to dest address.
	 * @param market The address of the market.
	 * @param account The account of which the rewards are to be claimed.
	 * @param dest The account where to transfer the claimed rewards.
	 * @param accrue Should accrue the rewards and interest before claiming.
	 * @param setId ID stores the amount of rewards claimed.
	 */
	function claimRewardsTo(
		address market,
		address account,
		address dest,
		bool accrue,
		uint256 setId
	) public returns (string memory eventName_, bytes memory eventParam_) {
		//in reward token decimals
		uint256 rewardsOwed = cometRewards.getRewardOwed(market, account).owed;
		cometRewards.claimTo(market, account, dest, accrue);

		setUint(setId, rewardsOwed);

		eventName_ = "LogRewardsClaimedTo(address,address,address,uint256,uint256,bool)";
		eventParam_ = abi.encode(
			market,
			account,
			dest,
			rewardsOwed,
			setId,
			accrue
		);
	}
}

contract ConnectV2CompoundV3Rewards is CompoundV3RewardsResolver {
	string public name = "CompoundV3Rewards-v1.0";
}
