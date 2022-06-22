//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import "./interface.sol";

contract Helpers is DSMath, Basic {
	/**
	 * @param token The address of token to be bridged.(For USDC: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)
	 * @param hopRouter The address of hop l1Bridge.
	 * @param chainId The Id of the destination chain.(For POLYGON : 137)
	 * @param recipient The address to recieve the token on destination chain.
	 * @param amount The total amount sent by user (Includes bonder fee, destination chain Tx cost).
	 * @param amountOutMin minimum amount of token out for swap
	 * @param deadline The deadline for the transaction (Recommended - Date.now() + 604800 (1 week))
	 */
	struct BridgeParams {
		address token;
		address recipient;
		address router;
		uint256 targetChainId;
		uint256 amount;
		uint256 destinationAmountOutMin;
		uint256 destinationDeadline;
	}

	function _sendToL2(BridgeParams memory params, bool isNative) internal {
		IHopRouter router = IHopRouter(params.router);

		uint256 nativeTokenAmt = isNative ? params.amount : 0;
		if (!isNative) {
			TokenInterface tokenContract = TokenInterface(params.token);
			approve(tokenContract, params.router, params.amount);
		}

		router.sendToL2{ value: nativeTokenAmt }(
			params.targetChainId,
			params.recipient,
			params.amount,
			params.destinationAmountOutMin,
			params.destinationDeadline,
			address(0), // relayer address
			0 // relayer fee
		);
	}
}
