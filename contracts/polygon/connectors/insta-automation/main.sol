//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title InstaAutomation
 * @dev Insta-Aave-v3-Automation
 */

import "./events.sol";
import "./interfaces.sol";

abstract contract Resolver is Events {
	InstaAaveAutomation internal immutable automation =
		InstaAaveAutomation(0x4dDc35489042db14434E19cE205963aa72Ecd722);

	function submitAutomationRequest(
		uint256 safeHealthFactor,
		uint256 thresholdHealthFactor
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		automation.submitAutomationRequest(
			safeHealthFactor,
			thresholdHealthFactor
		);

		(_eventName, _eventParam) = (
			"LogSubmitAutomation(uint256,uint256)",
			abi.encode(safeHealthFactor, thresholdHealthFactor)
		);
	}

	function cancelAutomationRequest()
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		automation.cancelAutomationRequest();
		(_eventName, _eventParam) = ("LogCancelAutomation()", "0x");
	}

	function updateAutomationRequest(
		uint256 safeHealthFactor,
		uint256 thresholdHealthFactor
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		automation.updateAutomation(safeHealthFactor, thresholdHealthFactor);

		(_eventName, _eventParam) = (
			"LogUpdateAutomation(uint256,uint256)",
			abi.encode(safeHealthFactor, thresholdHealthFactor)
		);
	}
}

contract ConnectV2InstaAaveAutomation is Resolver {
	string public constant name = "Insta-Aave-Automation-v1";
}
