// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract Events {
	event LogSupply(
		address indexed token_,
		uint256 amount_,
		address itoken_,
		uint256 itokenAmount_,
		uint256 getId,
		uint256 setId
	);

	event LogSupplyItoken(
		address indexed token_,
		uint256 amount_,
		address itoken_,
		uint256 itokenAmount_,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		address indexed token_,
		uint256 amt_,
		address itoken_,
		uint256 itokenAmount_,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawItoken(
		address indexed token,
		uint256 amt_,
		address itoken_,
		uint256 itokenAmount_,
		uint256 getId,
		uint256 setId
	);

	event LogClaimReward(
		address indexed user_,
		address indexed token_,
		uint256[] updatedRewards_,
		uint256[] setId
	);
}
