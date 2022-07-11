//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Insta dex simulation.
 * @dev swap.
 */

import { Events } from "./events.sol";
import "./helpers.sol";

abstract contract InstaDexSimulationResolver is Events, Helpers {
	/**
	 * @dev Simulation swap using Insta dex swap contract
	 * @param sellToken The token to sell/swap
	 * @param buyToken The token to buy
	 * @param sellAmount The sell token amount
	 * @param buyAmount The buy token amount
	 * @param setId Set token amount at this ID in `InstaMemory` Contract.
	 * @param getId Get token amount at this ID in `InstaMemory` Contract.
	 */
	function swap(
		address sellToken,
		address buyToken,
		uint256 sellAmount,
		uint256 buyAmount,
		uint256 setId,
		uint256 getId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		sellAmount = getUint(getId, sellAmount);
		uint256 nativeAmount;

		if (sellToken == ethAddr) {
			sellAmount = sellAmount == uint256(-1)
				? address(this).balance
				: sellAmount;
			nativeAmount = sellAmount;
		} else {
			TokenInterface tokenContract = TokenInterface(sellToken);

			sellAmount = sellAmount == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: sellAmount;

			approve(tokenContract, address(dexSimulation), sellAmount);
		}

		InstaDexSimulation(dexSimulation).swap{ value: nativeAmount }(
			sellToken,
			buyToken,
			sellAmount,
			buyAmount
		);

		setUint(setId, buyAmount);

		_eventName = "LogSimulateSwap(address,address,uint256,uint256)";
		_eventParam = abi.encode(sellToken, buyToken, sellAmount, buyAmount);
	}
}

contract ConnectV2InstaDexSimulation is InstaDexSimulationResolver {
	string public name = "Instadapp-DEX-Simulation-v1";
}
