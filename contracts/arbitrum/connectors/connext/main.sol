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
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function xcall(XCallParams memory params, uint256 getId, uint256 setId)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amount = getUint(getId, params.amount);
		TokenInterface tokenContract = TokenInterface(params.asset);
		bool isNative = params.asset == ethAddr;

		if (isNative) {
			_amount = _amount == uint256(-1) ? address(this).balance : _amount;
			params.asset = wethAddr;
			tokenContract = TokenInterface(params.asset);
			// xcall does not take native asset, must wrap 
			convertEthToWeth(true, tokenContract, _amount);

		} else {
			_amount = _amount == uint256(-1) ? tokenContract.balanceOf(address(this)) : _amount;
		}

		params.amount = _amount;
		approve(tokenContract, connextAddr, _amount);
		_xcall(params);

		setUint(setId, _amount);
		_eventName = "LogXCall(uint32,address,address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			params.destination,
			params.to,
			params.asset,
			params.delegate,
			params.amount,
			params.slippage,
			getId,
			setId
		);
	}
}

contract ConnectV2ConnextArbitrum is ConnextResolver {
	string public constant name = "Connext-v1.0";
}
