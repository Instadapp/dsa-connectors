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
