//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface EulerTokenInterface {
	function balanceOf(address _user) external view returns (uint256);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function allowance(address, address) external returns (uint256);
}

interface IEulerMarkets {
	function enterMarket(uint256 subAccountId, address newMarket) external;

	function getEnteredMarkets(address account)
		external
		view
		returns (address[] memory);

	function exitMarket(uint256 subAccountId, address oldMarket) external;

	function underlyingToEToken(address underlying)
		external
		view
		returns (address);

	function underlyingToDToken(address underlying)
		external
		view
		returns (address);
}

interface IEulerExecute {
	struct EulerBatchItem {
		bool allowError;
		address proxyAddr;
		bytes data;
	}

	struct EulerBatchItemResponse {
		bool success;
		bytes result;
	}

	function batchDispatch(
		EulerBatchItem[] calldata items,
		address[] calldata deferLiquidityChecks
	) external;

	function deferLiquidityCheck(address account, bytes memory data) external;
}
