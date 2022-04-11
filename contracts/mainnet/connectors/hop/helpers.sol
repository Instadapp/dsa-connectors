//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import "./interface.sol";

contract Helpers is DSMath, Basic {
	/**
	 * @param token The address of token to be bridged.(For USDC: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)
	 * @param chainId The Id of the destination chain.(For POLYGON : 137)
	 * @param recipient The address to recieve the token on destination chain.
	 * @param amount The total amount sent by user (Includes bonder fee, destination chain Tx cost).
	 * @param amountOutMin minimum amount of token out for swap
	 * @param deadline The deadline for the transaction (Recommended - Date.now() + 604800 (1 week))
	 */
	struct BridgeParams {
		address token;
		uint256 chainId;
		address recipient;
		uint256 amount;
		uint256 amountOutMin;
		uint256 deadline;
	}

	function _sendToL2(BridgeParams memory params) internal {
		IHopRouter router = _getRouter(params.token);

		TokenInterface tokenContract = TokenInterface(params.token);
		approve(tokenContract, address(router), params.amount);

		router.sendToL2(
			params.chainId,
			params.recipient,
			params.amount,
			params.amountOutMin,
			params.deadline,
			address(0), // relayer address
			0 // relayer fee
		);
	}

	function _getRouter(address token_)
		internal
		pure
		returns (IHopRouter router)
	{
		if (token_ == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)
			//USDC l1Bridge
			router = IHopRouter(0x3666f603Cc164936C1b87e207F36BEBa4AC5f18a);
		else if (token_ == 0xdAC17F958D2ee523a2206206994597C13D831ec7)
			//USDT l1Bridge
			router = IHopRouter(0x3E4a3a4796d16c0Cd582C382691998f7c06420B6);
		else if (token_ == 0x7c9f4C87d911613Fe9ca58b579f737911AAD2D43)
			//WMATIC l1Bridge
			router = IHopRouter(0x22B1Cbb8D98a01a3B71D034BB899775A76Eb1cc2);
		else if (token_ == 0x6B175474E89094C44Da98b954EedeAC495271d0F)
			//DAI l1Bridge
			router = IHopRouter(0x3d4Cc8A61c7528Fd86C55cfe061a78dCBA48EDd1);
		else if (token_ == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
			//WETH l1Bridge
			router = IHopRouter(0xb8901acB165ed027E32754E0FFe830802919727f);
		else if (token_ == 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)
			//WBTC l1Bridge
			router = IHopRouter(0xb98454270065A31D71Bf635F6F7Ee6A518dFb849);
		else revert("Invalid token migration");
	}
}
