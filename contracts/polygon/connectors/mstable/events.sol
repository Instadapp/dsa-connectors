pragma solidity ^0.7.6;

contract Events {
	// TODO: Events go here
	event LogDeposit(address token, uint256 amount, address path);
	event LogWithdraw(address token, uint256 amount, address path);
	event LogClaimReward(
		address token,
		uint256 amount,
		address platformToken,
		uint256 platformAmount
	);
}
