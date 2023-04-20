// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./variables.sol";
import { Basic } from "../../common/basic.sol";

contract Helpers is Variables, Basic {
	function claimableArbTokens(address user) public view returns (uint256) {
		return ARBITRUM_TOKEN_DISTRIBUTOR.claimableTokens(user);
	}
}