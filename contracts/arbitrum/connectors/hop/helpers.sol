//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import "./interface.sol";

contract Helpers is DSMath, Basic {
	/**
	 * @param token The address of token to be bridged.(For USDC: 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)
	 * @param targetChainId The Id of the destination chain.(For MAINNET : 1)
	 * @param router The address of hop router.
	 * @param recipient The address to recieve the token on destination chain.
	 * @param amount The total amount sent by user (Includes bonder fee, destination chain Tx cost).
	 * @param bonderFee The fee to be recieved by bonder at destination chain.
	 * @param sourceAmountOutMin minimum amount of token out for swap on source chain.
	 * @param sourceDeadline The deadline for the source chain transaction (Recommended - Date.now() + 604800 (1 week))
	 * @param destinationAmountOutMin minimum amount of token out for bridge on target chain, zero for L1 bridging
	 * @param destinationDeadline The deadline for the target chain transaction (Recommended - Date.now() + 604800 (1 week)), zero for L1 bridging
	 */
	struct BridgeParams {
		address token;
		address router;
		address recipient;
		uint256 targetChainId;
		uint256 amount;
		uint256 bonderFee;
		uint256 sourceAmountOutMin;
		uint256 sourceDeadline;
		uint256 destinationAmountOutMin;
		uint256 destinationDeadline;
	}

	function _swapAndSend(BridgeParams memory params, bool isEth) internal {
		IHopRouter router = IHopRouter(params.router);

		uint256 nativeTokenAmt = isEth ? params.amount : 0;
		if (!isEth) {
			TokenInterface tokenContract = TokenInterface(params.token);
			approve(tokenContract, params.router, params.amount);
		}

		router.swapAndSend{ value: nativeTokenAmt }(
			params.targetChainId,
			params.recipient,
			params.amount,
			params.bonderFee,
			params.sourceAmountOutMin,
			params.sourceDeadline,
			params.destinationAmountOutMin,
			params.destinationDeadline
		);
	}
}
