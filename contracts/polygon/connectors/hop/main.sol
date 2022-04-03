//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Hop.
 * @dev Cross chain Bridge.
 */

import { TokenInterface, MemoryInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import "./interface.sol";
import "./helpers.sol";
import "./events.sol";

abstract contract Resolver is Helpers {
	/**
	 * @dev Bridge Token.
	 * @notice Bridge Token on HOP.
	 * @param token The address of token to be bridged.(For USDC: 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)
	 * @param chainId The Id of the destination chain.(For MAINNET : 1)
	 * @param recipientOnL1 The address to recieve the token on destination chain (Layer 1).
	 * @param amount The total amount sent by user (Includes bonder fee, destination chain Tx cost).
	 * @param bonderFee The fee to be recieved by bonder at destination chain.
	 * @param amountOutMin minimum amount of token out for swap
	 * @param deadline The deadline for the transaction (Recommended - Date.now() + 604800 (1 week))
	 * @param destinationAmountOutMin minimum amount of token out for bridge
	 * @param destinationDeadline The deadline for the transaction (Recommended - Date.now() + 604800 (1 week))
	 * @param getId ID to retrieve amtA.
	 */
	function sendToL1(
		address token,
		uint256 chainId,
		address recipientOnL1,
		uint256 amount,
		uint256 bonderFee,
		uint256 amountOutMin,
		uint256 deadline,
		uint256 destinationAmountOutMin,
		uint256 destinationDeadline,
		uint256 getId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amount);

		bool isMatic = token == maticAddr;
		address _token = isMatic ? wmaticAddr : token;

		TokenInterface tokenContract = TokenInterface(_token);

		if (isMatic) {
			_amt = _amt == uint256(-1) ? address(this).balance : _amt;
			convertMaticToWmatic(isMatic, tokenContract, _amt);
		} else {
			_amt = _amt == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: _amt;
		}

		require(
			destinationAmountOutMin == 0,
			"destinationAmountOutMin != 0, sending to L1"
		);
		require(
			destinationDeadline == 0,
			"destinationDeadline != 0, sending to L1"
		);

		_swapAndSend(
			_token,
			chainId,
			recipientOnL1,
			_amt,
			bonderFee,
			amountOutMin,
			deadline,
			destinationAmountOutMin,
			destinationDeadline
		);

		_eventName = "LogSendToL1(address,uint256,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_token,
			chainId,
			recipientOnL1,
			_amt,
			bonderFee,
			amountOutMin,
			deadline,
			destinationAmountOutMin,
			destinationDeadline,
			getId
		);
	}

	/**
	 * @dev Send to L2 .
	 * @notice Bridge Token on HOP.
	 * @param token The address of token to be bridged.(For USDC: 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)
	 * @param chainId The Id of the destination chain.(For MAINNET : 1)
	 * @param recipientOnL2 The address to recieve the token on destination chain (Layer 2).
	 * @param amount The total amount sent by user (Includes bonder fee, destination chain Tx cost).
	 * @param bonderFee The fee to be recieved by bonder at destination chain.
	 * @param amountOutMin minimum amount of token out for swap
	 * @param deadline The deadline for the transaction (Recommended - Date.now() + 604800 (1 week))
	 * @param destinationAmountOutMin minimum amount of token out for bridge
	 * @param destinationDeadline The deadline for the transaction (Recommended - Date.now() + 604800 (1 week))
	 * @param getId ID to retrieve amtA.
	 */
	function sendToL2(
		address token,
		uint256 chainId,
		address recipientOnL2,
		uint256 amount,
		uint256 bonderFee,
		uint256 amountOutMin,
		uint256 deadline,
		uint256 destinationAmountOutMin,
		uint256 destinationDeadline,
		uint256 getId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amount);

		bool isMatic = token == maticAddr;
		address _token = isMatic ? wmaticAddr : token;

		TokenInterface tokenContract = TokenInterface(_token);

		if (isMatic) {
			_amt = _amt == uint256(-1) ? address(this).balance : _amt;
			convertMaticToWmatic(isMatic, tokenContract, _amt);
		} else {
			_amt = _amt == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: _amt;
		}

		_swapAndSend(
			_token,
			chainId,
			recipientOnL2,
			_amt,
			bonderFee,
			amountOutMin,
			deadline,
			destinationAmountOutMin,
			destinationDeadline
		);

		_eventName = "LogSendToL2(address,uint256,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_token,
			chainId,
			recipientOnL2,
			_amt,
			bonderFee,
			amountOutMin,
			deadline,
			destinationAmountOutMin,
			destinationDeadline,
			getId
		);
	}
}

contract ConnectV2HopPolygon is Resolver {
	string public constant name = "Hop-v1.0";
}
