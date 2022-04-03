//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogBridge(
		address token,
		uint256 chainId,
		address recipient,
		uint256 amount,
		uint256 bonderFee,
		uint256 amountOutMin,
		uint256 deadline,
		uint256 destinationAmountOutMin,
		uint256 destinationDeadline,
		uint256 getId
	);
}
