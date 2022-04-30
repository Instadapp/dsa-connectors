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
	 * @param buyAddr token to be bought
	 * @param sellAddr token to be sold
	 * @param fee pool fees for buyAddr-sellAddr token pair
	 * @param buyAmt amount of token to be bought
	 * @param getId Id to get buyAmt
	 * @param setId Id to store sellAmt
	 */
	function buy(
		address buyAddr,
		address sellAddr,
		uint24 fee,
		uint256 buyAmt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _buyAmt = getUint(getId, buyAmt);
		(
			TokenInterface _buyAddr,
			TokenInterface _sellAddr
		) = changeMaticAddress(buyAddr, sellAddr);

		bool isMatic = address(_sellAddr) == wmaticAddr;
		convertMaticToWmatic(isMatic, _sellAddr, uint256(-1));
		approve(_sellAddr, address(swapRouter), uint256(-1));
		ISwapRouter.ExactOutputSingleParams memory params;

		{
			params = ISwapRouter.ExactOutputSingleParams({
				tokenIn: sellAddr,
				tokenOut: buyAddr,
				fee: fee,
				recipient: address(this),
				deadline: block.timestamp + 1,
				amountOut: _buyAmt,
				amountInMaximum: uint256(-1),
				sqrtPriceLimitX96: 0
			});
		}

		uint256 _sellAmt = swapRouter.exactOutputSingle(params);

		isMatic = address(_buyAddr) == wmaticAddr;
		convertWmaticToMatic(isMatic, _buyAddr, _buyAmt);

		setUint(setId, _sellAmt);

		_eventName = "LogBuy(address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			buyAddr,
			sellAddr,
			_buyAmt,
			_sellAmt,
			getId,
			setId
		);
	}

	/**
	 * @dev Sell Function
	 * @notice Swap token(sellAddr) with token(buyAddr), sell token to get maximum amount of buy token
	 * @param buyAddr token to be bought
	 * @param sellAddr token to be sold
	 * @param fee pool fees for buyAddr-sellAddr token pair
	 * @param sellAmt amount of token to be sold
	 * @param getId Id to get sellAmount
	 * @param setId Id to store buyAmount
	 */
	function sell(
		address buyAddr,
		address sellAddr,
		uint24 fee,
		uint256 sellAmt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _sellAmt = getUint(getId, sellAmt);
		(
			TokenInterface _buyAddr,
			TokenInterface _sellAddr
		) = changeMaticAddress(buyAddr, sellAddr);

		if (_sellAmt == uint256(-1)) {
			_sellAmt = sellAddr == maticAddr
				? address(this).balance
				: _sellAddr.balanceOf(address(this));
		}

		bool isMatic = address(_sellAddr) == wmaticAddr;
		convertMaticToWmatic(isMatic, _sellAddr, _sellAmt);
		approve(_sellAddr, address(swapRouter), _sellAmt);
		ISwapRouter.ExactInputSingleParams memory params;

		{
			params = ISwapRouter.ExactInputSingleParams({
				tokenIn: sellAddr,
				tokenOut: buyAddr,
				fee: fee,
				recipient: address(this),
				deadline: block.timestamp + 1,
				amountIn: _sellAmt,
				amountOutMinimum: 0,
				sqrtPriceLimitX96: 0
			});
		}

		uint256 _buyAmt = swapRouter.exactInputSingle(params);

		isMatic = address(_buyAddr) == wmaticAddr;
		convertWmaticToMatic(isMatic, _buyAddr, _buyAmt);

		setUint(setId, _buyAmt);

		_eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			buyAddr,
			sellAddr,
			_buyAmt,
			_sellAmt,
			getId,
			setId
		);
	}
}

contract ConnectV2UniswapV3Polygon is UniswapResolver {
	string public constant name = "UniswapV3-v1";
}
