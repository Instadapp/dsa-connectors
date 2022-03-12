// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import { Helpers } from "./helper.sol";

contract Events {
	event LogSupply(
		address indexed token,
		address from,
		uint256 value,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(uint96 indexed NFTID);

	event LogTransferPosition(uint96 indexed NFTID);

	event LogAddLiquidity(
		uint96 indexed NFTID,
		uint256 amount0,
		uint256 amount1,
		uint256 minAmount0,
		uint256 minAmount1,
		uint256 deadline,
		uint256[] getId,
		uint256[] setId
	);

	event LogRemoveLiquidity(
		uint96 indexed NFTID,
		uint256 liquidity,
		uint256 amount0Min,
		uint256 amount1Min,
		uint256[] getId,
		uint256[] setID
	);

	event LogBorrow(
		uint96 NFTID,
		address token,
		uint256 amount_,
		uint256 getId,
		uint256 setId
	);

	event LogPayback(
		uint96 NFTID,
		address token,
		uint256 amount_,
		uint256 getId,
		uint256 setId
	);

	event LogCollectFees(uint96 NFTID, uint256[] setId);

	event LogDepositNFT(uint96 NFTID);

	event LogWithdrawNFT(uint96 NFTID);

	event LogStake(
		address rewardToken,
		uint256 startTime,
		uint256 endTime,
		address refundee,
		uint96 indexed NFTID
	);

	event LogUnStake(
		address rewardToken,
		uint256 startTime,
		uint256 endTime,
		address refundee,
		uint96 indexed NFTID
	);

	event LogClaimStakingRewards(address rewardToken, uint96 NFTID);

	event LogClaimBorrowingRewards(BorrowingReward[] rewards_, uint96 NFTID);

	event LogClaimBorrowingRewards(
		uint96 NFTID,
		address[] rewardTokens_,
		uint256[] rewardAmounts_
	);

	event LogLiquidate0(
		uint256 paybackAmount0,
		uint256 paybackAmount1,
		uint256 incentiveAmount0,
		uint256 incentiveAmount1
	);

	event LogLiquidate1(
		uint256 paybackAmount0,
		uint256 paybackAmount1,
		uint256 incentiveAmount0,
		uint256 incentiveAmount1
	);
}
