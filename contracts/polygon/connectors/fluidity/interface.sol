// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IProtocolModule {
	function supply(address token_, uint256 amount_)
		external
		returns (uint256 itokenAmount_);

	function withdraw(address token_, uint256 amount_)
		external
		returns (uint256 itokenAmount_);

	function withdrawItoken(address token_, uint256 itokenAmount_)
		external
		returns (uint256 amount_);

	function claim(address user_, address token_)
		external
		returns (uint256[] memory updatedRewards_);
}
