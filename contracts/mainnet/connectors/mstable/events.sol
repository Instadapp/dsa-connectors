pragma solidity ^0.7.6;

contract Events {
	event LogDeposit(address token, uint256 amount, address path, bool stake);
	event LogWithdraw(
		address token,
		uint256 amount,
		address path,
		bool unstake
	);
	event LogClaimRewards(address token, uint256 amount);
	event LogSwap(
		address from,
		address to,
		uint256 amountIn,
		uint256 amountOut
	);
}
