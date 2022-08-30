//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { CometInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	function getBaseToken(address market)
		internal
		view
		returns (address baseToken)
	{
		baseToken = CometInterface(market).baseToken();
	}

	function _supply(
		address market,
		address token,
		uint256 amt
	) internal payable returns (bool success) {
		bytes memory data = abi.encodeWithSignature(
			"supply(address, uint256)",
			token,
			amt
		);
		(success, ) = market.delegateCall(data);
	}

	function _withdraw(
		address market,
		address token,
		uint256 amt
	) internal payable returns (bool success) {
		bytes memory data = abi.encodeWithSignature(
			"withdraw(address, uint256)",
			token,
			amt
		);
		(success, ) = market.delegateCall(data);
	}

	function getAccountSupplyBalanceOfAsset(
		address account,
		address market,
		address asset
	) internal view returns (uint256 balance) {
		if (asset == getBaseToken(market)) {
			//balance in base
			balance = CometInterface(market).balanceOf(account);
		} else {
			//balance in asset denomination
			balance = uint256(
				CometInterface(market).userCollateral(account, asset).balance
			);
		}
	}
}
