//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface InstaAaveAutomation {
	function submitAutomationRequest(
		uint256 safeHealthFactor,
		uint256 thresholdHealthFactor
	) external;

	function cancelAutomationRequest() external;

	function updateAutomation(
		uint256 safeHealthFactor,
		uint256 thresholdHealthFactor
	) external;
}

interface AccountInterface {
	function enable(address) external;

	function disable(address) external;

	function isAuth(address) external view returns (bool);
}
