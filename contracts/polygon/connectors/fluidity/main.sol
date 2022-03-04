// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

/**
 * @title Fluidity.
 * @dev
 */

import { Events } from "./events.sol";
import { Helpers } from "./helper.sol";
import { TokenInterface } from "../../common/interfaces.sol";

abstract contract FluidityResolver is Events, Helpers {
	/**
	 * @dev
	 * @notice
	 * @param token_ Token Address.
	 * @param amt Token Amount.
	 * @param getId ID to retrieve amt
	 * @param setId ID stores the amount of tokens supplied
	 */
	function supply(
		address token_,
		uint256 amt,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 amt_ = getUint(getId, amt);

		TokenInterface tokenContract = TokenInterface(token_);
		amt_ = amt_ == type(uint256).max
			? tokenContract.balanceOf(address(this))
			: amt_;

		Helpers.approve(tokenContract, address(this), amt_);
		uint256 itokenAmount_ = protocolModule.supply(token_, amt_);

		setUint(setId, amt_);

		_eventName = "LogSupply(address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			address(token_),
			amt_,
			itokenAmount_,
			getId,
			setId
		);
	}

	/**
	 * @dev
	 * @notice
	 * @param token_ Token Address.
	 * @param amtount Token Amount.
	 * @param getId ID to retrieve amt
	 * @param setId ID stores the amount of tokens withdrawn
	 */
	function withdraw(
		address token_,
		uint256 amount_,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 amt_ = getUint(getId, amount_);

		uint256 itokenAmount_ = protocolModule.withdraw(token_, amt_);

		setUint(setId, amt_);

		_eventName = "LogWithdraw(address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			address(token_),
			amt_,
			itokenAmount_,
			getId,
			setId
		);
	}

	/**
	 * @dev
	 * @notice
	 * @param token_ Token Address.
	 * @param itokenAmtount iToken Amount.
	 * @param getId ID to retrieve amt
	 * @param setId ID stores the amount of itokens withdrawn
	 */

	function withdrawItoken(
		address token_,
		uint256 itokenAmount_,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 amt_ = getUint(getId, itokenAmount_);

		uint256 amount_ = protocolModule.withdrawItoken(token_, amt_);

		setUint(setId, amt_);

		_eventName = "LogWithdrawItoken(address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(address(token_), amt_, amount_, getId, setId);
	}

	/**
	 * @dev
	 * @notice
	 * @param user_  User Address.
	 * @param token_ Token Address.
	 * @param setId Array of setId stores the amount of claimed Rewards
	 */
	function claim(
		address user_,
		address token_,
		uint256[] memory setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256[] memory updatedRewards_ = protocolModule.claim(user_, token_);

		for (uint256 i = 0; i < updatedRewards_.length; i++) {
			setUint(setId[i], updatedRewards_[i]);
		}

		_eventName = "LogClaimReward(address,address,uint256[])";
		_eventParam = abi.encode(
			address(user_),
			address(token_),
			updatedRewards_
		);
	}
}

contract ConnectV2FluidityP1 is FluidityResolver {
	string public constant name = "FluidityP1M2";
}
