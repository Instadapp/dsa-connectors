pragma solidity ^0.7.0;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { SwapData } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	/**
	 * @dev UniswapV3 Swap Router Address
	 */
	address internal constant V3_SWAP_ROUTER_ADDRESS =
		0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

	/**
	 * @dev UniswapV3 swapHelper
	 * @param swapData - Struct defined in interfaces.sol
	 */
	function _swapHelper(SwapData memory swapData)
		internal
		returns (uint256 buyAmt)
	{
		(uint256 _buyDec, uint256 _sellDec) = getTokensDec(
			swapData.buyToken,
			swapData.sellToken
		);
		uint256 _sellAmt18 = convertTo18(_sellDec, swapData._sellAmt);
		uint256 _slippageAmt = convert18ToDec(
			_buyDec,
			wmul(swapData.unitAmt, _sellAmt18)
		);

		uint256 initalBal = getTokenBal(swapData.buyToken);

		// solium-disable-next-line security/no-call-value
		(bool success, ) = V3_SWAP_ROUTER_ADDRESS.call(swapData.callData);
		if (!success) revert("uniswapV3-swap-failed");

		uint256 finalBal = getTokenBal(swapData.buyToken);

		buyAmt = sub(finalBal, initalBal);
		require(_slippageAmt <= buyAmt, "Too much slippage");
	}

	/**
	 * @dev Gets the swapping data from auto router sdk
	 * @param swapData Struct with multiple swap data defined in interfaces.sol
	 * @param setId Set token amount at this ID in `InstaMemory` Contract.
	 */
	function _swap(SwapData memory swapData, uint256 setId)
		internal
		returns (SwapData memory)
	{
		bool isEthSellToken = address(swapData.sellToken) == ethAddr;
		bool isEthBuyToken = address(swapData.buyToken) == ethAddr;

		swapData.sellToken = isEthSellToken
			? TokenInterface(wethAddr)
			: swapData.sellToken;
		swapData.buyToken = isEthBuyToken
			? TokenInterface(wethAddr)
			: swapData.buyToken;

		convertEthToWeth(isEthSellToken, swapData.sellToken, swapData._sellAmt);

		approve(
			TokenInterface(swapData.sellToken),
			V3_SWAP_ROUTER_ADDRESS,
			swapData._sellAmt
		);

		swapData._buyAmt = _swapHelper(swapData);

		convertWethToEth(isEthBuyToken, swapData.buyToken, swapData._buyAmt);

		setUint(setId, swapData._buyAmt);

		return swapData;
	}
}
