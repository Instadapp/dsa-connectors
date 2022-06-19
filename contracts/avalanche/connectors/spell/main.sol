//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Spell.
 * @dev Cast on DSAs.
 */

// import files
import { AccountInterface } from "../../common/interfaces.sol";
import { SpellHelpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract Spell is SpellHelpers, Events {
	/**
	 *@dev Cast spells on DSA.
	 *@param targetDSA target DSA to cast spells on.
	 *@param connectors connector names.
	 *@param datas datas for the cast.
	 */
	function castDSA(
		address targetDSA,
		string[] memory connectors,
		bytes[] memory datas
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(instaList.accountID(targetDSA) != 0, "not-a-DSA");

		AccountInterface(targetDSA).cast(connectors, datas, address(0));

		_eventName = "LogCastDSA(address,string[],bytes[])";
		_eventParam = abi.encode(targetDSA, connectors, datas);
	}
}

contract ConnectV2SpellConnectorPolygon is Spell {
	string public name = "Spell-Connector-v1.0";
}
