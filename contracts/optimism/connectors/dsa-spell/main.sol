//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title DSA Spell.
 * @dev Cast spells on DSA.
 */

import { AccountInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Events } from "./events.sol";

abstract contract DSASpellsResolver is Events, Stores {
	/**
	 *@dev Casts spells on a DSA, caller DSA should be an auth of the target DSA. Reverts if any spell failed.
	 *@notice Interact with a target DSA by casting spells on it.
	 *@param targetDSA target DSA to cast spells on.
	 *@param connectors Array of connector names (For example, ["1INCH-A", "BASIC-A"]).
	 *@param datas Array of connector calldatas (function selectors encoded with parameters).
	 */
	function castOnDSA(
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

		_eventName = "LogCastOnDSA(address,string[],bytes[])";
		_eventParam = abi.encode(targetDSA, connectors, datas);
	}

	/**
	 *@dev Casts spell on caller DSA. Stops casting further spells as soon as a spell gets casted successfully.
	 * Reverts if none of the spells is successful.
	 *@notice Casts the first successful spell on the DSA.
	 *@param connectors Array of connector names, in preference order, if any (For example, ["1INCH-A", "ZEROX-A"]).
	 *@param datas Array of connector calldatas (function selectors encoded with parameters).
	 */
	function castAny(string[] memory connectors, bytes[] memory datas)
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

		string memory _connectorName;
		string memory _eventName;
		bytes memory _eventParam;
		bytes memory returnData;
		bool success;

		for (uint256 i = 0; i < _length; i++) {
			(success, returnData) = _connectors[i].delegatecall(datas[i]);

			if (success) {
				_connectorName = connectors[i];
				(_eventName, _eventParam) = abi.decode(
					returnData,
					(string, bytes)
				);
				break;
			}
		}
		require(success, "dsa-spells-failed");

		eventName = "LogCastAny(string[],string,string,bytes)";
		eventParam = abi.encode(
			connectors,
			_connectorName,
			_eventName,
			_eventParam
		);
	}
}

contract ConnectV2DSASpellOptimism is DSASpellsResolver {
	string public name = "DSA-Spell-v1.0";
}
