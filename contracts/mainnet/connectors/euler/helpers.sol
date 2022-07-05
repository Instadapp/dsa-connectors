//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./variables.sol";
import { Basic } from "../../common/basic.sol";

contract Helpers is Basic, Variables {

    /**
	 * @dev Get total collateral balance for an asset
	 */
	function getEnteredMarkets()
		internal
		view
		returns (address[] memory enteredMarkets)
	{
		enteredMarkets = markets.getEnteredMarkets(address(this));
	}

}
