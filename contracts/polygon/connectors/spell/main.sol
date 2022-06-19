//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title DSA Spell.
 * @dev Cast spells on DSA.
 */

// import files
import { AccountInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Events } from "./events.sol";

abstract contract DSASpell is Events, Stores {
	/**
	 *@dev Cast spells on DSA.
	 *@param targetDSA target DSA to cast spells on.
	 *@param connectors Array of connector names.
	 *@param datas Array of connector calldatas.
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

		AccountInterface(targetDSA).cast(connectors, datas, address(this));

		_eventName = "LogCastDSA(address,string[],bytes[])";
		_eventParam = abi.encode(targetDSA, connectors, datas);
	}

	/**
	 *@dev Perform spells.
	 *@param connectors Array of connector names.
	 *@param datas Array of connector calldatas.
	 */
	function castSpells(string[] memory connectors, bytes[] memory datas)
		external
		payable
		returns (string memory eventName, bytes memory eventParam)
	{
		uint256 _length = connectors.length;
		require(_length > 0, "zero-length-not-allowed");
		require(datas.length == _length, "calldata-length-invalid");

		(bool isOk, address[] memory _connectors) = instaConnectors
			.isConnectors(connectors);
		require(isOk, "connector-names-invalid");

		string[] memory _eventNames = new string[](_length);
		bytes[] memory _eventParams = new bytes[](_length);

		for (uint256 i = 0; i < _length; i++) {
			(bool success, bytes memory returnData) = _connectors[i]
				.delegatecall(datas[i]);
			require(success, "spells-failed");
			(_eventNames[i], _eventParams[i]) = abi.decode(
				returnData,
				(string, bytes)
			);
		}

		eventName = "LogCastSpells(string[],bytes[])";
		eventParam = abi.encode(_eventNames, _eventParams);
	}
}

contract ConnectV2DSASpellPolygon is DSASpell {
	string public name = "DSA-Spell-v1.0";
}
