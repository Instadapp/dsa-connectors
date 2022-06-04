//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import { InstaConnectors } from "../../common/interfaces.sol";

abstract contract Helper {
	/**
	 * @dev Instadapp Connectors Registry
	 */
	InstaConnectors internal constant instaConnectors =
		InstaConnectors(0x2A00684bFAb9717C21271E0751BCcb7d2D763c88);

	struct InputData {
		address buyAddr;
		address sellAddr;
		uint256 sellAmt;
		uint256[] unitAmts;
		bytes[] callDatas;
		uint256 setId;
	}
}

contract SwapHelpers is Helper {
	/**
	 *@dev Performs the swap usign the dex aggregators.
	 *@param _connectors name of the connectors in preference order.
	 *@param _inputData data for the swap cast.
	 */
	function _swap(string[] memory _connectors, InputData memory _inputData)
		internal
		returns (
			bool success,
			bytes memory returnData,
			string memory _connector
		)
	{
		require(_connectors.length > 0, "zero-length-not-allowed");
		require(
			_inputData.unitAmts.length == _connectors.length,
			"unitAmts-length-invalid"
		);
		require(
			_inputData.callDatas.length == _connectors.length,
			"callDatas-length-invalid"
		);

		for (uint256 i = 0; i < _connectors.length; i++) {
			string[] memory _target = new string[](1);
			bytes[] memory _data = new bytes[](1);
			bytes4 swapData = bytes4(
				keccak256("swap(address,address,uint256,uint256,bytes,uint256)")
			);

			string memory _1INCH = "1INCH-A";
			if (keccak256(bytes(_connectors[i])) == keccak256(bytes(_1INCH))) {
				swapData = bytes4(
					keccak256(
						"sell(address,address,uint256,uint256,bytes,uint256)"
					)
				);
			}

			_target[0] = _connectors[i];
			_data[0] = abi.encodeWithSelector(
				swapData,
				_inputData.buyAddr,
				_inputData.sellAddr,
				_inputData.sellAmt,
				_inputData.unitAmts[i],
				_inputData.callDatas[i],
				_inputData.setId
			);

			bytes4 _castData = bytes4(
				keccak256("cast(string[],bytes[],address)")
			);
			bytes memory castData = abi.encodeWithSelector(
				_castData,
				_target,
				_data,
				address(0)
			);

			(success, returnData) = instaConnectors
				.connectors(_connectors[i])
				.delegatecall(castData);

			if (success) {
				_connector = _connectors[i];
				break;
			}
		}
	}
}
