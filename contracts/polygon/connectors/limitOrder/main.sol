pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

import { Helpers } from "./helpers.sol";
import { IUniLimitOrder } from "./interface.sol";
import { TokenInterface } from "../../common/interfaces.sol";

/**
 * @title LimitOrderConnector.
 * @dev Connector for Limit Order Swap on Uni V3.
 */
contract LimitOrderConnector is Helpers {

    /**
     * @dev Create NFT
     * @notice Create NFT
     * @param token0_ Token0 Address.
     * @param token1_ Token1 Amount.
     * @param fee_ Pool fee.
     * @param tickLower_ Lower tick.
     * @param tickUpper_ Upper tick.
     * @param amount_ Amount to deposit
     * @param tokenDirectn_ Token 0 to 1 bool
     */
	function create(
		address token0_,
		address token1_,
		uint24 fee_,
		int24 tickLower_,
		int24 tickUpper_,
		uint256 amount_,
		bool tokenDirectn_
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		MintParams memory params_ = MintParams(
			token0_,
			token1_,
			fee_,
			tickLower_,
			tickUpper_,
			amount_,
			tokenDirectn_
		);

		(
			uint256 tokenId_,
			uint256 liquidity_,
			uint256 minAmount_
		) = _createPosition(params_);

		eventName_ = "LogCreate(uint256,uint256,uint256,int24,int24)";
		eventParam_ = abi.encode(
			tokenId_,
			liquidity_,
			minAmount_,
			params_.tickLower,
			params_.tickUpper
		);
	}

    /**
     * @dev Close NFT in Mid
     * @notice Close NFT in Mid
     * @param tokenId_ Token ID.
     * @param amountAMin_ Amount A Min.
     * @param amountBMin_ Amount B Min.
     */
	function closeMid(
		uint256 tokenId_,
		uint256 amountAMin_,
		uint256 amountBMin_
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		(uint128 liquidity_, uint256 amount0, uint256 amount1) = limitCon_
			.closeMidPosition(tokenId_, amountAMin_, amountBMin_);

		eventName_ = "LogWithdrawMid(uint256,uint256,uint256,uint256)";
		eventParam_ = abi.encode(tokenId_, liquidity_, amount0, amount1);
	}

    /**
     * @dev Close NFT after swap completion
     * @notice Close NFT after swap completion
     * @param tokenId_ Token ID.
     */
	function closeFull(uint256 tokenId_)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 closeAmount_ = limitCon_.closeFullPosition(tokenId_);

		eventName_ = "LogWithdrawFull(uint256,uint256)";
		eventParam_ = abi.encode(tokenId_, closeAmount_);
	}
}

contract ConnectV2LimitOrder is LimitOrderConnector {
	string public constant name = "Limit-Order-Connector";
}
