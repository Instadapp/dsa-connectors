//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";

interface IHopRouter {
	function sendToL2(
		uint256 chainId,
		address recipient,
		uint256 amount,
		uint256 amountOutMin,
		uint256 deadline,
		address relayer,
		uint256 relayerFee
	) external payable;
}
