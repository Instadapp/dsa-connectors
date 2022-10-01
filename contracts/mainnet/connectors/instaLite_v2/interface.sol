//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IInstaLite {
	function token() external view returns (address);

	function importPosition(
		address flashTkn_,
		uint256 flashAmt_,
		uint256 route_,
		uint256 stEthAmt_,
		uint256 wethAmt_,
		uint256 getId,
		uint256 setId
	) external;
}
