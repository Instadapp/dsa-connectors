//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import "./interface.sol";

contract Helpers is DSMath, Basic {
	/**
	 * @param token The address of token to be bridged.(For USDC: 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8)
	 * @param hopRouter The address of hop l2AmmWrapper.
	 * @param chainId The Id of the destination chain.(For MAINNET : 1)
	 * @param recipient The address to recieve the token on destination chain.
	 * @param amount The total amount sent by user (Includes bonder fee, destination chain Tx cost).
	 * @param bonderFee The fee to be recieved by bonder at destination chain.
	 * @param amountOutMin minimum amount of token out for swap
	 * @param deadline The deadline for the transaction (Recommended - Date.now() + 604800 (1 week))
	 * @param destinationAmountOutMin minimum amount of token out for bridge, zero for L1 bridging
	 * @param destinationDeadline The deadline for the transaction (Recommended - Date.now() + 604800 (1 week)), zero for L1 bridging
	 */
	struct BridgeParams {
		address token;
		address recipient;
		address hopRouter;
		uint256 chainId;
		uint256 amount;
		uint256 bonderFee;
		uint256 amountOutMin;
		uint256 deadline;
		uint256 destinationAmountOutMin;
		uint256 destinationDeadline;
	}

	function _swapAndSend(BridgeParams memory params) internal {
		IHopRouter router = IHopRouter(params.hopRouter);

		TokenInterface tokenContract = TokenInterface(params.token);
		approve(tokenContract, params.hopRouter, params.amount);

		router.swapAndSend(
			params.chainId,
			params.recipient,
			params.amount,
			params.bonderFee,
			params.amountOutMin,
			params.deadline,
			params.destinationAmountOutMin,
			params.destinationDeadline
		);
	}
}
