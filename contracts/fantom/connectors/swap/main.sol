//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Swap.
 * @dev Swap integration for DEX Aggregators.
 */

// import files
import { SwapHelpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract Swap is SwapHelpers, Events {
	/**
	 * @dev Swap ETH/ERC20_Token using dex aggregators.
	 * @notice Swap tokens from exchanges like 1INCH, 0x etc, with calculation done off-chain.
	 * @param _connectors The name of the connectors like 1INCH-A, 0x etc, in order of their priority.
	 * @param _datas Encoded function call data including function selector encoded with parameters.
	 */
	function swap(string[] memory _connectors, bytes[] memory _datas)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(bool success, bytes memory returnData, string memory connector) = _swap(
			_connectors,
			_datas
		);

		require(success, "swap-Aggregator-failed");
		(string memory eventName, bytes memory eventParam) = abi.decode(
			returnData,
			(string, bytes)
		);

		_eventName = "LogSwapAggregator(string[],string,string,bytes)";
		_eventParam = abi.encode(_connectors, connector, eventName, eventParam);
	}
}

contract ConnectV2SwapAggregatorFantom is Swap {
	string public name = "Swap-Aggregator-v1";
}
