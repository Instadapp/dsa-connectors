pragma solidity ^0.7.6;

contract Events {
	event LogDeposit(address token, uint256 amount, address path);
	event LogWithdraw(address token, uint256 amount, address path);
	event LogClaimRewards(
		address token,
		uint256 amount,
		address platformToken,
		uint256 platformAmount
	);
	event LogSwap(
		address from,
		address to,
		uint256 amountIn,
		uint256 amountOut
	);
}
