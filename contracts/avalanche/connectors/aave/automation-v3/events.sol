//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
	event LogCancelAutomation();

	event LogSubmitAutomation(uint256 safeHF, uint256 thresholdHF);

	event LogUpdateAutomation(uint256 safeHF, uint256 thresholdHF);
}
