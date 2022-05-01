//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {TokenInterface} from "../../../common/interfaces.sol";
import {DSMath} from "../../../common/math.sol";
import {Basic} from "../../../common/basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	/**
	 * @dev uniswap v3 Swap Router
	 */
	ISwapRouter constant swapRouter =
		ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
	
	struct BuyInfo {
		address buyAddr;		//token to be bought		
		address sellAddr;		//token to be sold
		uint24 fee;				//pool fees for buyAddr-sellAddr token pair
		uint256 unitAmt;		//The unit amount of sellAmt/buyAmt with slippage
		uint256 buyAmt;			//amount of token to be bought
		uint256 getId;			//Id to get buyAmt
		uint256 setId;			//Id to store sellAmt
	}

	struct SellInfo {
		address buyAddr;		//token to be bought		
		address sellAddr;		//token to be sold
		uint24 fee;				//pool fees for buyAddr-sellAddr token pair
		uint256 unitAmt;		//The unit amount of buyAmt/sellAmt with slippage.
		uint256 sellAmt;		//amount of token to be bought
		uint256 getId;			//Id to get buyAmt
		uint256 setId;			//Id to store sellAmt
	}
}