//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IConnext {
	function xcall(
		uint32 _destination,
		address _to,
		address _asset,
		address _delegate,
		uint256 _amount,
		uint256 _slippage,
		bytes calldata _callData
	) external payable returns (bytes32);
}
