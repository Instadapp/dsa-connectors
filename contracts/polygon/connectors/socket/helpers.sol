//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./interface.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";

contract Helpers is Basic {
	address internal immutable registry =
		0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0;

	function _socketBridge(bytes memory _txData, uint256 _nativeTokenAmt)
		internal
		returns (bool _success)
	{
		(_success, ) = registry.call{ value: _nativeTokenAmt }(_txData);
	}

	/**
	 * @dev Gets Allowance target from registry.
	 * @param _route route number
	 */
	function getAllowanceTarget(uint256 _route)
		internal
		view
		returns (address _allowanceTarget)
	{
		RouteData memory data = ISocketRegistry(registry).routes(_route);
		_allowanceTarget = data.route;
		require(_allowanceTarget != address(0), "allowanceTarget-not-valid");
	}
}
