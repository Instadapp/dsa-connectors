//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Uniswap v3 swap.
 * @dev Decentralized Exchange.
 */

import {TokenInterface} from "../../../common/interfaces.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";
import "./interface.sol";

abstract contract UniswapResolver is Helpers, Events {
    /**
	 * @dev Buy Function
	 * @notice Swap token(sellAddr) with token(buyAddr), buy token with minimum sell token
	 * @param buyData Data input for the buy action
	 */
	function buy(
		BuyInfo memory buyData
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _buyAmt = getUint(buyData.getId, buyData.buyAmt);
		uint _slippageAmt;
		bool isEth;
		ISwapRouter.ExactOutputSingleParams memory params;
		
		(TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(
			buyData.buyAddr,
			buyData.sellAddr
		);
		
		_slippageAmt = convert18ToDec(_sellAddr.decimals(),
			wmul(buyData.unitAmt, convertTo18(_buyAddr.decimals(), _buyAmt))
		);		
		isEth = address(_sellAddr) == wethAddr;
		convertEthToWeth(isEth, _sellAddr, _slippageAmt);
		approve(_sellAddr, address(swapRouter), _slippageAmt);

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

		isEth = address(_buyAddr) == wethAddr;
		convertWethToEth(isEth, _buyAddr, _buyAmt);

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
	 * @param sellData Data input for the buy action
	 */
	function sell(
		SellInfo memory sellData
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _sellAmt = getUint(sellData.getId, sellData.sellAmt);
		(TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(
			sellData.buyAddr,
			sellData.sellAddr
		);

		if (_sellAmt == uint(-1)) {						
			_sellAmt = sellData.sellAddr == ethAddr
				? address(this).balance
				: _sellAddr.balanceOf(address(this));
		}

		uint _slippageAmt = convert18ToDec(_buyAddr.decimals(),
		    wmul(sellData.unitAmt, convertTo18(_sellAddr.decimals(), _sellAmt))
		);

		bool isEth = address(_sellAddr) == wethAddr;
		convertEthToWeth(isEth, _sellAddr, _sellAmt);
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

		isEth = address(_buyAddr) == wethAddr;
		convertWethToEth(isEth, _buyAddr, _buyAmt);

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

contract ConnectV2UniswapV3 is UniswapResolver {
	string public constant name = "UniswapV3-v1";
}
