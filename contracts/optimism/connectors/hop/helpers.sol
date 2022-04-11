//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import "./interface.sol";

contract Helpers is DSMath, Basic {
	/**
	 * @param token The address of token to be bridged.(For USDC: 0x7f5c764cbc14f9669b88837ca1490cca17c31607)
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
		uint256 chainId;
		address recipient;
		uint256 amount;
		uint256 bonderFee;
		uint256 amountOutMin;
		uint256 deadline;
		uint256 destinationAmountOutMin;
		uint256 destinationDeadline;
	}

	function _swapAndSend(BridgeParams memory params) internal {
		IHopRouter router = _getRouter(params.token);

		TokenInterface tokenContract = TokenInterface(params.token);
		approve(tokenContract, address(router), params.amount);

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

	function _getRouter(address token_)
		internal
		pure
		returns (IHopRouter router)
	{
		if (token_ == 0x7F5c764cBc14f9669B88837ca1490cCa17c31607)
			//USDC l2AmmWrapper
			router = IHopRouter(0x2ad09850b0CA4c7c1B33f5AcD6cBAbCaB5d6e796);
		else if (token_ == 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58)
			//USDT l2AmmWrapper
			router = IHopRouter(0x7D269D3E0d61A05a0bA976b7DBF8805bF844AF3F);
		else if (token_ == 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1)
			//DAI l2AmmWrapper
			router = IHopRouter(0xb3C68a491608952Cb1257FC9909a537a0173b63B);
		else if (token_ == 0x4200000000000000000000000000000000000006)
			//WETH l2AmmWrapper
			router = IHopRouter(0x86cA30bEF97fB651b8d866D45503684b90cb3312);
		else if (token_ == 0x68f180fcCe6836688e9084f035309E29Bf0A2095)
			//WBTC l2AmmWrapper
			router = IHopRouter(0x2A11a98e2fCF4674F30934B5166645fE6CA35F56);
		else revert("Invalid token migration");
	}
}
