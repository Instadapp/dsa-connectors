//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Uniswap v3 swap.
 * @dev Decentralized Exchange.
 */

import { TokenInterface } from "../../../common/interfaces.sol";
import { Events } from "./events.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import "./interface.sol";

abstract contract UniswapResolver is DSMath, Events, Basic {
	/**
	 * @dev uniswap v3 Swap Router
	 */
	ISwapRouter constant swapRouter =
		ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

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
		(TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(
			buyAddr,
			sellAddr
		);

		// uint _slippageAmt = convert18ToDec(_sellAddr.decimals(),
		//     wmul(unitAmt, convertTo18(_buyAddr.decimals(), _buyAmt))
		// );

		bool isEth = address(_sellAddr) == wethAddr;
		convertEthToWeth(isEth, _sellAddr, uint256(-1));
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

		isEth = address(_buyAddr) == wethAddr;
		convertWethToEth(isEth, _buyAddr, _buyAmt);

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
		(TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(
			buyAddr,
			sellAddr
		);

		if (_sellAmt == uint256(-1)) {
			_sellAmt = sellAddr == ethAddr
				? address(this).balance
				: _sellAddr.balanceOf(address(this));
		}

		// uint _slippageAmt = convert18ToDec(_buyAddr.decimals(),
		//     wmul(unitAmt, convertTo18(_sellAddr.decimals(), _sellAmt))
		// );
		// require(_slippageAmt <= _expectedAmt, "Too much slippage");

		bool isEth = address(_sellAddr) == wethAddr;
		convertEthToWeth(isEth, _sellAddr, _sellAmt);
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

		isEth = address(_buyAddr) == wethAddr;
		convertWethToEth(isEth, _buyAddr, _buyAmt);

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

contract ConnectV2UniswapV3 is UniswapResolver {
	string public constant name = "UniswapV3-v1";
}
