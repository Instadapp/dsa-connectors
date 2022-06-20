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
	function swap(
		address sellToken,
		address buyToken,
		uint256 sellAmount,
		uint256 buyAmount,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		if (sellToken == maticAddr) {
			sellAmount = sellAmount == uint256(-1)
				? address(this).balance
				: sellAmount;
		} else {
			TokenInterface tokenContract = TokenInterface(sellToken);

			sellAmount = sellAmount == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: sellAmount;

			approve(tokenContract, address(dexSimulation), sellAmount);
		}

		InstaDexSimulation(dexSimulation).swap{ value: sellAmount }(
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
	string public name = "InstaDexSimulation-v1";
}
