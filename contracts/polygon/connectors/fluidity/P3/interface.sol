// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import { Helpers } from "./helper.sol";
interface INFT {
	function safeTransferFrom(
		address token,
		address from,
		address to,
		uint256 value
	) external;
}


interface IProtocolModule {
	function withdraw(uint96 NFTID_) external;

	function transferPosition(uint96 NFTID_, address to_) external;

	function addLiquidity(
		uint96 NFTID_,
		uint256 amount0_,
		uint256 amount1_,
		uint256 minAmount0_,
		uint256 minAmount1_,
		uint256 deadline_
	) external returns (uint256 exactAmount0_, uint256 exactAmount1_);

	function removeLiquidity(
		uint96 NFTID_,
		uint256 liquidity_,
		uint256 amount0Min_,
		uint256 amount1Min_
	) external returns (uint256 exactAmount0_, uint256 exactAmount1_);

	function borrow(
		uint96 NFTID_,
		address token_,
		uint256 amount_
	) external;

	function payback(
		uint96 NFTID_,
		address token_,
		uint256 amount_
	) external;

	function collectFees(uint96 NFTID_)
		external
		returns (uint256 amount0_, uint256 amount1_);

	function depositNFT(uint96 NFTID_)
        external;

	function withdrawNFT(uint96 NFTID_)
        external;

	function stake(
        address rewardToken_,
        uint256 startTime_,
        uint256 endTime_,
        address refundee_,
        uint96 NFTID_
    ) external;

	function unstake(
        address rewardToken_,
        uint256 startTime_,
        uint256 endTime_,
        address refundee_,
        uint96 NFTID_
    ) external;


	function claimStakingRewards(address rewardToken_, uint96 NFTID_)
        public
        returns (uint256 rewards_);

	function claimBorrowingRewards(uint96 NFTID_)
	public
	returns (BorrowingReward[] memory);

	function claimBorrowingRewards(uint96 NFTID_, address token_)
        public
        
        returns (
            address[] memory rewardTokens_,
            uint256[] memory rewardAmounts_
        );

	 function liquidate0(Liquidate0Parameters memory liquidate0Parameters_)
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

	function liquidate1(Liquidate1Parameters memory liquidate1Parameters_)
        external
        returns (
            uint256,
            uint256,
            address[] memory,
            uint256[] memory
        );

	



	
}
