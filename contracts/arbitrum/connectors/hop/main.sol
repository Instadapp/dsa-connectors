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
	 * @param params BridgeParams struct for bridging
	 * @param getId ID to retrieve amount from last spell.
	 */
	function bridge(BridgeParams memory params, uint256 getId)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		if (params.targetChainId == 1) {
			require(
				params.destinationAmountOutMin == 0,
				"destinationAmountOutMin != 0, sending to L1"
			);
			require(
				params.destinationDeadline == 0,
				"destinationDeadline != 0, sending to L1"
			);
		}

		params.amount = getUint(getId, params.amount);
		TokenInterface tokenContract = TokenInterface(params.token);

		if (params.token == wethAddr) {
			convertWethToEth(true, tokenContract, params.amount);
			params.token = ethAddr;
		}

		bool isEth = params.token == ethAddr;

		if (isEth) {
			params.amount = params.amount == uint256(-1)
				? address(this).balance
				: params.amount;
		} else {
			params.amount = params.amount == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: params.amount;
		}

		_swapAndSend(params, isEth);

		_eventName = "LogBridge(address,uint256,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			params.token,
			params.targetChainId,
			params.recipient,
			params.amount,
			params.bonderFee,
			params.sourceAmountOutMin,
			params.sourceDeadline,
			params.destinationAmountOutMin,
			params.destinationDeadline,
			getId
		);
	}
}

contract ConnectV2HopArbitrum is Resolver {
	string public constant name = "Hop-v1.0";
}
