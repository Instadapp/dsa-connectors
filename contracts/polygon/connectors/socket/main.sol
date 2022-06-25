//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title Socket.
 * @dev Multi-chain Bridge Aggregator.
 */

import "./events.sol";
import "./helpers.sol";

abstract contract SocketResolver is Helpers {
	/**
	 * @dev Bridge Token.
	 * @notice Bridge Token on Socket.
	 * @param _token token address on source chain
	 * @param _txData tx data for calling
	 * @param _route route number
	 * @param _amount amount to bridge
	 * @param _targetChain Target chain ID
	 * @param _recipient address of the recipient on the target chain
	 */
	function bridge(
		address _token,
		bytes memory _txData,
		uint256 _route,
		uint256 _amount,
		uint256 _targetChain,
		address _recipient
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		bool isNative = _token == maticAddr;
		uint256 nativeTokenAmt;

		if (isNative) {
			_amount = _amount == uint256(-1) ? address(this).balance : _amount;
			nativeTokenAmt = _amount;
		} else {
			TokenInterface tokenContract = TokenInterface(_token);

			_amount = _amount == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: _amount;
			tokenContract.approve(getAllowanceTarget(_route), _amount);
		}

		require(_socketBridge(_txData, nativeTokenAmt), "Socket-swap-failed");

		uint256 _sourceChain;
		assembly {
			_sourceChain := chainid()
		}

		_eventName = "LogSocketBridge(address,uint256,uint256,uint256,address)";
		_eventParam = abi.encode(
			_token,
			_amount,
			_sourceChain,
			_targetChain,
			_recipient
		);
	}
}

contract ConnectV2SocketPolygon is SocketResolver {
	string public constant name = "Socket-v1.0";
}
