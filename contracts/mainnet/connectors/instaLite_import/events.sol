//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogImport(
		address flashTkn,
		uint256 flashAmt,
		uint256 route,
		uint256 stEthAmt,
		uint256 wethAmt,
		uint256 iEthAmount,
		uint256[] getIds,
		uint256 setId
	);
}
