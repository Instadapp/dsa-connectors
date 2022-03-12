// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

/**
 * @title Fluidity.
 * @dev
 */

import { Events } from "./events.sol";
import { Helpers } from "./helper.sol";
//import { TokenInterface } from "../../common/interfaces.sol";
import {TokenInterface} from "../../../common/interfaces.sol";

abstract contract FluidityResolver is Events, Helpers {
	function supplyNft(
		address token,
		address from,
		uint256 value,
		uint256 getId,
		uint256 setId
	)
		public
		returns (
			//payable
			string memory _eventName,
			bytes memory _eventParam
		)
	{
		uint256 value_ = getUint(getId, value);
		TokenInterface tokenContract = TokenInterface(token_);
		value_ = value_ == type(uint256).max
			? tokenContract.balanceOf(address(this))
			: value_;
		approve(tokenContract, address(protocolModule), value_);

		nftManager.safeTransferFrom(
			token,
			from,
			address(protocolModule),
			value_
		);

		_eventName = "LogSupply(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, from, value_, getId, setId);
	}

	function withdrawNFT(uint96 NFTID)
		public
		returns (
			//payable
			string memory _eventName,
			bytes memory _eventParam
		)
	{
		protocolModule.withdraw(NFTID);

		_eventName = "LogWithdraw(uint256)";
		_eventParam = abi.encode(NFTID);
	}

	function transferPosition(uint96 NFTID, address to)
		public
		returns (string memory _eventName, bytes memory _eventParam)
	{
		protocolModule.transferPosition(NFTID, to);

		_eventName = "LogTransferPosition(uint96)";
		_eventParam = abi.encode(NFTID);
	}

	function addLiquidity(
		uint96 NFTID,
		uint256 amount0,
		uint256 amount1,
		uint256 minAmount0,
		uint256 minAmount1,
		uint256 deadline,
		uint256[] memory getId,
		uint256[] memory setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		amount0_ = getUint(getId[0], amount0);
		amount1_ = getUint(getId[1], amount1);
		(uint256 exactAmount0_, uint256 exactAmount1_) = protocolModule
			.addLiquidity(
				NFTID,
				amount0_,
				amount1_,
				minAmount0,
				minAmount1,
				deadline
			);

		setUint(setId[0], exactAmount0_);
		setUint(setId[1], exactAmount1_);

		_eventName = "LogAddLiquidity(uint96,uint256,uint256,uint256,uint256,uint256,uint256[],uint256[])";
		_eventParam = abi.encode(
			NFTID,
			amount0_,
			amount1_,
			minAmount0,
			minAmount1,
			deadline,
			getId,
			setId
		);
	}

	// get id
	function removeLiquidity(
		uint96 NFTID,
		uint256 liquidity,
		uint256 amount0Min,
		uint256 amount1Min,
		uint256 getId,
		uint256[] memory setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 liquidity_ = getUint(getId, liquidity);
		(uint256 exactAmount0_, uint256 exactAmount1_) = protocolModule
			.removeLiquidity(NFTID, liquidity_, amount0Min, amount1Min);

		setUint(setId[0], exactAmount0_);
		setUint(setId[1], exactAmount1_);

		_eventName = "LogRemoveLiquidity(uint96,uint256,uint256,uint256,uint256[],uint256[])";
		_eventParam = abi.encode(
			NFTID,
			liquidity_,
			amount0Min,
			amount1Min,
			getId,
			setId
		);
	}

	function borrow(
		uint96 NFTID,
		address token,
		uint256 amount,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 amount_ = getUint(getId, amount);
		protocolModule.borrow(NFTID, token, amount);
		setUint(setId, amount_);
		_eventName = "LogBorrow(uint96,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(NFTID, token, amount_, getId, setId);
	}

	function payback(
		uint96 NFTID,
		address token,
		uint256 amount
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 amount_ = getUint(getId, amount);
		(uint256 amount0_, uint256 amount1_) = protocolModule.payback(
			NFTID,
			token,
			amount
		);
		setUint(setId, amount_);
		_eventName = "LogPayback(uint96,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(NFTID, token, amount_, getId, setId);
	}

	function collectFees(uint96 NFTID, uint256[] memory setId)
		public
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(uint256 amount0_, uint256 amount1_) = protocolModule.collectFees(
			NFTID
		);
		setUint(setId[0], amount0_);
		setUint(setId[1], amount1_);
		_eventName = "LogCollectFees(uint96,uint256[])";
		_eventParam = abi.encode(NFTID, setId);
	}

	function depositNftToStaker(uint96 NFTID)
		public
		returns (string memory _eventName, bytes memory _eventParam)
	{
		protocolModule.depositNFT(NFTID);
		_eventName = "LogDepositNFT(uint96)";
		_eventParam = abi.encode(NFTID);
	}

	function withdrawNftFromStaker(uint96 NFID)
		public
		returns (string memory _eventName, bytes memory _eventParam)
	{
		protocolModule.withdrawNFT(NFTID);
		_eventName = "LogWithdrawNFT(uint96)";
		_eventParam = abi.encode(NFTID);
	}

	function stake(
		address rewardToken,
		uint256 startTime,
		uint256 endTime,
		address refundee,
		uint96 NFTID
	) public returns (string memory _eventName, bytes memory _eventParam) {
		protocolModule.stake(rewardToken, startTime, endTime, refundee, NFTID);
		_eventName = "LogStake(address,uint256,uint256,address,uint96)";
		_eventParam = abi.encode(
			rewardToken,
			startTime,
			endTime,
			refundee,
			NFTID
		);
	}

	function unstake(
		address rewardToken,
		uint256 startTime,
		uint256 endTime,
		address refundee,
		uint96 NFTID
	) public returns (string memory _eventName, bytes memory _eventParam) {
		protocolModule.unstake(
			rewardToken,
			startTime,
			endTime,
			refundee,
			NFTID
		);
		_eventName = "LogUnStake(address,uint256,uint256,address,uint96)";
		_eventParam = abi.encode(
			rewardToken,
			startTime,
			endTime,
			refundee,
			NFTID
		);
	}

	function claimStakingRewards(address rewardToken, uint96 NFTID)
		public
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 rewards_ = protocolModule.claimStakingRewards(
			rewardToken,
			NFTID
		);
		_eventName = "LogClaimStakingRewards(address,uint96)";
		_eventParam = abi.encode(rewardToken, NFTID);
	}

	function claimBorrowingRewards(uint96 NFTID)
		public
		returns (string memory _eventName, bytes memory _eventParam)
	{
		BorrowingReward[] memory rewards_ = protocolModule
			.claimBorrowingRewards(NFTID);

		_eventName = "LogClaimBorrowingRewards(BorrowingReward[],uint96)";
		_eventParam = abi.encode(rewards_, NFTID);
	}

	function claimBorrowingRewards(uint96 NFTID, address token)
		public
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(
			address[] memory rewardTokens_,
			uint256[] memory rewardAmounts_
		) = protocolModule.claimBorrowingRewards(NFTID, token);

		_eventName = "LogClaimBorrowingRewards(uint96,address[],uint256[])";
		_eventParam = abi.encode(NFTID, rewardTokens_, rewardAmounts_);
	}

	function liquidate0(
		Liquidate0Parameters memory liquidate0Parameters_,
		uint256[] setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		Liquidate0Variables memory liquidate0Variables_;
		(
			uint256 paybackAmount0,
			uint256 paybackAmount1,
			uint256 incentiveAmount0,
			uint256 incentiveAmount1
		) = protocolModule.liquidate0(liquidate0Parameters_);

		setUint(setId[0], paybackAmount0);
		setUint(setId[1], paybackAmount1);
		setUint(setId[2], incentiveAmount0);
		setUint(setId[3], incentiveAmount1);

		_eventName = "LogLiquidate0(uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			paybackAmount0,
			paybackAmount1,
			incentiveAmount0,
			incentiveAmount1,
			setId
		);
	}

	function liquidate1(
		Liquidate1Parameters memory liquidate1Parameters_,
		uint256[] setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		(
			uint256 exactAmount0,
			uint256 exactAmount1,
			address[] memory markets,
			uint256[] memory paybackAmts
		) = protocolModule.liquidate1(liquidate1Parameters_);

		setUint(setID[0], exactAmount0);
		setUint(setID[1], exactAmount1);

		_eventName = "LogLiquidate1(uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			paybackAmount0,
			paybackAmount1,
			incentiveAmount0,
			incentiveAmount1,
			setId
		);
	}
}

contract ConnectV2FluidityP3 is FluidityResolver {
	string public constant name = "FluidityP3";
}
