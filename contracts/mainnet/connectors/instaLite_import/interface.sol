//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IInstaLite {
	function balanceOf(address account) external view virtual returns (uint256);

	function importPosition(
		address flashTkn_,
		uint256 flashAmt_,
		uint256 route_,
		address to_,
		uint256 stEthAmt_,
		uint256 wethAmt_
	) external;
}
