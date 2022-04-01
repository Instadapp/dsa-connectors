//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface instaLiteInterface {
	function supplyEth(address to_) external payable returns (uint256);

	function supply(
		address token_,
		uint256 amount_,
		address to_
	) external returns (uint256);

	function withdraw(uint256 amount_, address to_) external returns (uint256);
}
