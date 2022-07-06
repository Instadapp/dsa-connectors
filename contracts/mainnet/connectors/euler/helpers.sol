//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./variables.sol";
import "./events.sol";
import { Basic } from "../../common/basic.sol";

contract Helpers is Basic, Variables, Events {

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

	function getSubAccount(address primary, uint subAccountId) public pure returns (address) {
        require(subAccountId < 256, "sub-account-id-too-big");
        return address(uint160(primary) ^ uint160(subAccountId));
    }

	function checkIfEnteredMarket(address token) public view returns(bool) {
		address[] memory enteredMarkets = getEnteredMarkets();
		uint256 length = enteredMarkets.length;

		for(uint i = 0; i < length; i++) {
			if(enteredMarkets[i] == token) {
				return true;
			}
		}
		return false;
	}

}
