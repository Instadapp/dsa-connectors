//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Swap.
 * @dev Swap integration for DEX Aggregators.
 */

// import files
import { SwapHelpers } from "./helpers.sol";

abstract contract Swap is SwapHelpers {
	/**
	 * @dev Swap ETH/ERC20_Token using dex aggregators.
	 * @notice Swap tokens from exchanges like 1INCH, 0x etc, with calculation done off-chain.
	 * @param _connectors The name of the connectors like 1INCH-A, 0x etc, in order of their priority.
	 * @param _data Encoded function call data including function selector encoded with parameters.
	 */
	function swap(
		string[] memory _connectors,
		bytes[] memory _data
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(bool success, bytes memory returnData) = _swap(_connectors, _data);

		require(success, "swap-Aggregator-failed");
		(_eventName, _eventParam) = abi.decode(returnData, (string, bytes));
	}
}

contract ConnectV2SwapAggregatorAvalanche is Swap {
	string public name = "Swap-Aggregator-v1";
}
