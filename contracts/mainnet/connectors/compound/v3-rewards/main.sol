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
	 * @param setId ID stores the amount of rewards claimed.
	 */
	function claimRewards(
		address market,
		uint256 setId
	) public returns (string memory eventName_, bytes memory eventParam_) {
		uint256 rewardsOwed = cometRewards.getRewardOwed(market, address(this)).owed;
		cometRewards.claim(market, address(this), true);

		setUint(setId, rewardsOwed);

		eventName_ = "LogRewardsClaimed(address,address,uint256,uint256)";
		eventParam_ = abi.encode(market, address(this), rewardsOwed, setId);
	}

	/**
	 * @dev Claim rewards and interests accrued in supplied/borrowed base asset.
	 * @notice Claim rewards and interests accrued and transfer to dest address.
	 * @param market The address of the market.
	 * @param owner The account of which the rewards are to be claimed.
	 * @param to The account where to transfer the claimed rewards.
	 * @param setId ID stores the amount of rewards claimed.
	 */
	function claimRewardsOnBehalfOf(
		address market,
		address owner,
		address to,
		uint256 setId
	) public returns (string memory eventName_, bytes memory eventParam_) {
		//in reward token decimals
		uint256 rewardsOwed = cometRewards.getRewardOwed(market, owner).owed;
		cometRewards.claimTo(market, owner, to, true);

		setUint(setId, rewardsOwed);

		eventName_ = "LogRewardsClaimedOnBehalf(address,address,address,uint256,uint256)";
		eventParam_ = abi.encode(
			market,
			owner,
			to,
			rewardsOwed,
			setId
		);
	}
}

contract ConnectV2CompoundV3Rewards is CompoundV3RewardsResolver {
	string public name = "CompoundV3Rewards-v1.0";
}
