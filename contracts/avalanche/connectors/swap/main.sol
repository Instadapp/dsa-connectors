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
	 * @param buyAddr The address of the token to buy.(For MATIC: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param sellAddr The address of the token to sell.(For MATIC: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param sellAmt The amount of the token to sell.
	 * @param unitAmts The amount of buyAmt/sellAmt with slippage for respective DEXs.
	 * @param swapDatas The function selectors of swap methods of the DEXs.
	 * @param callDatas Data from APIs for respective DEXs.
	 * @param setId ID stores the amount of token brought.
	 */
	function swap(
		address buyAddr,
		address sellAddr,
		uint256 sellAmt,
		uint256[] memory unitAmts,
		bytes4[] memory swapDatas,
		bytes[] calldata callDatas,
		string[] memory _connectors,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		InputData memory inputData = InputData({
			buyAddr: buyAddr,
			sellAddr: sellAddr,
			sellAmt: sellAmt,
			unitAmts: unitAmts,
			swapDatas: swapDatas,
			callDatas: callDatas,
			setId: setId
		});

		(bool success, bytes memory returnData) = _swap(_connectors, inputData);

		require(success, "swap-Aggregator-failed");
		(_eventName, _eventParam) = abi.decode(returnData, (string, bytes));
	}
}

contract ConnectV2SwapAggregatorAvalanche is Swap {
	string public name = "Swap-Aggregator-v1";
}
