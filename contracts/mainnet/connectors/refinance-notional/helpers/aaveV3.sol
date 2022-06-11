//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { Helpers } from "../helpers.sol";

import { AaveV3DataProviderInterface, AaveV3PoolProviderInterface, AaveV3Interface } from "../interface.sol";
import { TokenInterface } from "../../../common/interfaces.sol";

contract AaveV3Helpers is Helpers {
	// payback token to Aave V2, amts sent already checked for MAX
	function _aaveV3PaybackOne(
		AaveV3Interface aave,
		TokenInterface token,
		uint256 amt,
		uint256 rateMode
	) internal {
		if (amt > 0) {
			bool isEth = address(token) == wethAddr;
			if (isEth) convertEthToWeth(isEth, token, amt);
			approve(token, address(aave), amt);
			aave.repay(address(token), amt, rateMode, address(this));
		}
	}

	function _aaveV3Payback(
		uint256 length,
		AaveV3Interface aave,
		TokenInterface[] memory tokens,
		uint256[] memory amts,
		uint256[] memory rateModes
	) internal {
		for (uint256 i = 0; i < length; i++) {
			_aaveV3PaybackOne(aave, tokens[i], amts[i], rateModes[i]);
		}
	}

	// withdraw aToken from aaveV2
	function _aaveV3WithdrawOne(
		AaveV3Interface aave,
		AaveV3DataProviderInterface aaveData,
		TokenInterface token,
		uint256 amt
	) internal returns (uint256 _amt) {
		if (amt > 0) {
			bool isEth = address(token) == wethAddr;
			aave.withdraw(address(token), amt, address(this));
			_amt = amt == uint256(-1)
				? getWithdrawBalanceV3(aaveData, address(token))
				: amt;
			convertWethToEth(isEth, token, _amt);
		}
	}

	function _aaveV3Withdraw(
		AaveV3Interface aave,
		AaveV3DataProviderInterface aaveData,
		uint256 length,
		TokenInterface[] memory tokens,
		uint256[] memory amts
	) internal returns (uint256[] memory) {
		uint256[] memory finalAmts = new uint256[](length);
		for (uint256 i = 0; i < length; i++) {
			finalAmts[i] = _aaveV3WithdrawOne(
				aave,
				aaveData,
				tokens[i],
				amts[i]
			);
		}
	}
}
