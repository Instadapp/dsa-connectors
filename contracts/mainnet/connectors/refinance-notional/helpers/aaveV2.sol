//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { Helpers } from "../helpers.sol";

import { AaveV2DataProviderInterface, AaveV2LendingPoolProviderInterface, AaveV2Interface } from "../interface.sol";
import { TokenInterface } from "../../../common/interfaces.sol";

contract AaveHelpers is Helpers {
	// payback token to Aave V2, amts sent already checked for MAX
	function _aaveV2PaybackOne(
		AaveV2Interface aave,
		TokenInterface token,
		uint256 amt,
		uint256 rateMode
	) internal {
		if (amt > 0) {
			bool isEth = address(token) == wethAddr;
			convertEthToWeth(isEth, token, amt);
			approve(token, address(aave), amt);
			aave.repay(address(token), amt, rateMode, address(this));
		}
	}

	function _aaveV2Payback(
		uint256 length,
		AaveV2Interface aave,
		TokenInterface[] memory tokens,
		uint256[] memory amts,
		uint256[] memory rateModes
	) internal {
		for (uint256 i = 0; i < length; i++) {
			_aaveV2PaybackOne(aave, tokens[i], amts[i], rateModes[i]);
		}
	}

	// withdraw aToken from aaveV2
	function _aaveV2WithdrawOne(
		AaveV2Interface aave,
		AaveV2DataProviderInterface aaveData,
		TokenInterface token,
		uint256 amt
	) internal returns (uint256 _amt) {
		if (amt > 0) {
			bool isEth = address(token) == wethAddr;
			aave.withdraw(address(token), amt, address(this));
			_amt = amt == uint256(-1)
				? getWithdrawBalanceV2(aaveData, address(token))
				: amt;
			convertWethToEth(isEth, token, _amt);
		}
	}

	function _aaveV2Withdraw(
		AaveV2Interface aave,
		AaveV2DataProviderInterface aaveData,
		uint256 length,
		TokenInterface[] memory tokens,
		uint256[] memory amts
	) internal returns (uint256[] memory) {
		uint256[] memory finalAmts = new uint256[](length);
		for (uint256 i = 0; i < length; i++) {
			finalAmts[i] = _aaveV2WithdrawOne(
				aave,
				aaveData,
				tokens[i],
				amts[i]
			);
		}
		return finalAmts;
	}
}
