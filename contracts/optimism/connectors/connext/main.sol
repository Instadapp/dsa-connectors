//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Connext.
 * @dev Cross chain bridge.
 */

import { TokenInterface, MemoryInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import "./interface.sol";
import "./helpers.sol";
import "./events.sol";

abstract contract ConnextResolver is Helpers {
	/**
	 * @dev Call xcall on Connext.
	 * @notice Call xcall on Connext.
	 * @param params XCallParams struct.
	 * @param getId ID to retrieve amount from last spell.
	 */
	function xcall(XCallParams memory params, uint256 getId)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		params.amount = getUint(getId, params.amount);
		TokenInterface tokenContract = TokenInterface(params.asset);

		_xcall(params);

		_eventName = "LogXCall(uint32,address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			params.destination,
			params.to,
      params.asset,
			params.delegate,
			params.amount,
			params.slippage,
			getId
		);
	}
}

contract ConnectV2ConnextOptimism is ConnextResolver {
	string public constant name = "Connext-v1.0";
}
