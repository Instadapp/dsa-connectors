pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import {Events} from "./events.sol";
import {Helpers} "./helpers.sol";
import { TokenInterface } from "../../common/interfaces.sol";

abstract contract FluidityP1M2 is Events, Helpers {
	function supply(
		address token_,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 amt_ = getUint(getId, amt);

		TokenInterface tokenContract = TokenInterface(token_);
		amt_ = amt_ == type(uint256).max
			? tokenContract.balanceOf(address(this))
			: amt_;

		uint256 itokenAmount_ = p1m2.supply(token_, amt_);

		setUint(setId, amt_);

		_eventName = "LogSupply(address,uint,uint,uint,uint)";
		_eventParam = abi.encode(
			address(token_),
			amt_,
			itokenAmount_,
			getId,
			setId
		);
	}

	function withdraw(
		address token_,
		uint256 amount_,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 amt_ = getUint(getId, amount_);
		TokenInterface tokenContract = TokenInterface(token_);
		amt_ = amt_ == type(uint256).max
			? tokenContract.balanceOf(address(this))
			: amt_;

		uint256 itokenAmount_ = p1m2.withdraw(token_, amt_);

		setUint(setId, amt_);

		_eventName = "LogWithdraw(address,uint,uint,uint,uint)";
		_eventParam = abi.encode(
			address(token_),
			amt_,
			itokenAmount_,
			getId,
			setId
		);
	}

	function withdrawItoken(
		address token_,
		uint256 itokenAmount_,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 amt_ = getUint(getId, itokenAmount_);
		TokenInterface tokenContract = TokenInterface(token_);
		amt_ = amt_ == type(uint256).max
			? tokenContract.balanceOf(address(this))
			: amt_;

		uint256 amount_ = p1m2.withdrawItoken(token_, amt_);

		setUint(setId, amt_);

		_eventName = "LogWithdrawItoken(address,uint,uint,uint,uint)";
		_eventParam = abi.encode(address(token_), amt_, amount_, getId, setId);
	}

	function claim(
		address user_,
		address token_,
		
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256[] memory updatedRewards_ = p1m2.claim(user_, token_);

		_eventName = "LogClaimReward(address,address,uint[])";
		_eventParam = abi.encode(
			address(user_),
			address(token_),
			updatedRewards_
		);
	}
}
