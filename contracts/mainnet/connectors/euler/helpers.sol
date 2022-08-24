//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./interface.sol";
import "./events.sol";
import { Basic } from "../../common/basic.sol";

contract Helpers is Basic, Events {

	address internal constant EULER_MAINNET =
		0x27182842E098f60e3D576794A5bFFb0777E025d3;
	IEulerMarkets internal constant markets =
		IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

	/**
	 * @dev Get sub account address
	 * @param primary address of user
	 * @param subAccountId sub-account id
	 */
	function getSubAccount(address primary, uint256 subAccountId)
		public
		pure
		returns (address)
	{
		require(subAccountId < 256, "sub-account-id-too-big");
		return address(uint160(primary) ^ uint160(subAccountId));
	}

	/**
	 * @dev Get Enetered markets for a user
	 * @param subAccountId sub-account id
	 */
	function getEnteredMarkets(uint256 subAccountId)
		internal
		view
		returns (address[] memory enteredMarkets)
	{
		address _subAccountAddress = getSubAccount(address(this), subAccountId);
		enteredMarkets = markets.getEnteredMarkets(_subAccountAddress);
	}

	/**
	 * @dev Check if the market is entered
	 * @param subAccountId sub-account id
	 * @param token token address
	 */
	function checkIfEnteredMarket(uint256 subAccountId, address token) public view returns (bool) {
		address[] memory enteredMarkets = getEnteredMarkets(subAccountId);
		uint256 length = enteredMarkets.length;

		for (uint256 i = 0; i < length; i++) {
			if (enteredMarkets[i] == token) {
				return true;
			}
		}
		return false;
	}
}
