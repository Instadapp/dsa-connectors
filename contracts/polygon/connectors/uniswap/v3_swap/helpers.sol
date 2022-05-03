//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { TokenInterface}  from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
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
		uint256 unitAmt;		//The unit amount of buyAmt/sellAmt with slippage
		uint256 sellAmt;		//amount of token to be bought
		uint256 getId;			//Id to get buyAmt
		uint256 setId;			//Id to store sellAmt
	}

	/**
	 * @dev Buy Function
	 * @notice Swap token(sellAddr) with token(buyAddr), buy token with minimum sell token
	  * @param buyData Data input for the buy action
	 */
	function _buy(
		BuyInfo memory buyData
	)
		internal
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _buyAmt = getUint(buyData.getId, buyData.buyAmt);
		(
			TokenInterface _buyAddr,
			TokenInterface _sellAddr
		) = changeMaticAddress(buyData.buyAddr, buyData.sellAddr);

		uint _slippageAmt = convert18ToDec(_sellAddr.decimals(),
		    wmul(buyData.unitAmt, convertTo18(_buyAddr.decimals(), _buyAmt))
		);

		bool isMatic = address(_sellAddr) == wmaticAddr;
		convertMaticToWmatic(isMatic, _sellAddr, _slippageAmt);
		approve(_sellAddr, address(swapRouter), _slippageAmt);
		ISwapRouter.ExactOutputSingleParams memory params;

		{
			params = ISwapRouter.ExactOutputSingleParams({
				tokenIn: buyData.sellAddr,
				tokenOut: buyData.buyAddr,
				fee: buyData.fee,
				recipient: address(this),
				deadline: block.timestamp + 1,
				amountOut: _buyAmt,
				amountInMaximum: _slippageAmt,		//require(_sellAmt <= amountInMaximum)
				sqrtPriceLimitX96: 0
			});
		}

		uint256 _sellAmt = swapRouter.exactOutputSingle(params);
		require(_slippageAmt >= _sellAmt, "Too much slippage");

		isMatic = address(_buyAddr) == wmaticAddr;
		convertWmaticToMatic(isMatic, _buyAddr, _buyAmt);

		setUint(buyData.setId, _sellAmt);

		_eventName = "LogBuy(address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			buyData.buyAddr,
			buyData.sellAddr,
			_buyAmt,
			_sellAmt,
			buyData.getId,
			buyData.setId
		);
	}

	/**
	 * @dev Sell Function
	 * @notice Swap token(sellAddr) with token(buyAddr), to get max buy tokens
	 * @param sellData Data input for the sell action
	 */
	function _sell(
		SellInfo memory sellData
	)
		internal
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _sellAmt = getUint(sellData.getId, sellData.sellAmt);
		(
			TokenInterface _buyAddr,
			TokenInterface _sellAddr
		) = changeMaticAddress(sellData.buyAddr, sellData.sellAddr);

		if (_sellAmt == uint(-1)) {	
			_sellAmt = sellData.sellAddr == maticAddr
				? address(this).balance
				: _sellAddr.balanceOf(address(this));
		}

		uint _slippageAmt = convert18ToDec(_buyAddr.decimals(),
		    wmul(sellData.unitAmt, convertTo18(_sellAddr.decimals(), _sellAmt))
		);

		bool isMatic = address(_sellAddr) == wmaticAddr;
		convertMaticToWmatic(isMatic, _sellAddr, _sellAmt);
		approve(_sellAddr, address(swapRouter), _sellAmt);
		ISwapRouter.ExactInputSingleParams memory params;

		{
			params = ISwapRouter.ExactInputSingleParams({
				tokenIn: sellData.sellAddr,
				tokenOut: sellData.buyAddr,
				fee: sellData.fee,
				recipient: address(this),
				deadline: block.timestamp + 1,
				amountIn: _sellAmt,
				amountOutMinimum: _slippageAmt,		//require(_buyAmt >= amountOutMinimum)
				sqrtPriceLimitX96: 0
			});
		}

		uint256 _buyAmt = swapRouter.exactInputSingle(params);
		require(_slippageAmt <= _buyAmt, "Too much slippage");

		isMatic = address(_buyAddr) == wmaticAddr;
		convertWmaticToMatic(isMatic, _buyAddr, _buyAmt);

		setUint(sellData.setId, _buyAmt);

		_eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			sellData.buyAddr,
			sellData.sellAddr,
			_buyAmt,
			_sellAmt,
			sellData.getId,
			sellData.setId
		);
	}
}