//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	/**
	 * @dev uniswap v3 Swap Router
	 */
	ISwapRouter02 constant swapRouter =
		ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

	struct BuyInfo {
		address buyAddr; //token to be bought
		address sellAddr; //token to be sold
		uint24 fee; //pool fees for buyAddr-sellAddr token pair
		uint256 unitAmt; //The unit amount of sellAmt/buyAmt with slippage
		uint256 buyAmt; //amount of token to be bought
	}

	struct SellInfo {
		address buyAddr; //token to be bought
		address sellAddr; //token to be sold
		uint24 fee; //pool fees for buyAddr-sellAddr token pair
		uint256 unitAmt; //The unit amount of sellAmt/buyAmt with slippage
		uint256 sellAmt; //amount of token to be bought
	}

	/**
	 * @dev Buy Function
	 * @notice Swap token(sellAddr) with token(buyAddr), buy token with minimum sell token
	 * @param buyData Data input for the buy action
	 * @param getId Id to get buyAmt
	 * @param setId Id to store sellAmt
	 */
	function _buy(
		BuyInfo memory buyData,
		uint256 getId,
		uint256 setId
	) internal returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _buyAmt = getUint(getId, buyData.buyAmt);

		(TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(
			buyData.buyAddr,
			buyData.sellAddr
		);

		uint256 _slippageAmt = convert18ToDec(
			_sellAddr.decimals(),
			wmul(buyData.unitAmt, convertTo18(_buyAddr.decimals(), _buyAmt))
		);
		bool isEth = address(buyData.sellAddr) == ethAddr;
		convertEthToWeth(isEth, _sellAddr, _slippageAmt);
		approve(_sellAddr, address(swapRouter), _slippageAmt);

		ExactOutputSingleParams memory params = ExactOutputSingleParams({
			tokenIn: address(_sellAddr),
			tokenOut: address(_buyAddr),
			fee: buyData.fee,
			recipient: address(this),
			amountOut: _buyAmt,
			amountInMaximum: _slippageAmt, //require(_sellAmt <= amountInMaximum)
			sqrtPriceLimitX96: 0
		});

		uint256 _sellAmt = swapRouter.exactOutputSingle(params);
		require(_slippageAmt >= _sellAmt, "Too much slippage");

		if (_slippageAmt > _sellAmt) {
			convertEthToWeth(isEth, _sellAddr, _slippageAmt - _sellAmt);
			approve(_sellAddr, address(swapRouter), 0);
		}
		isEth = address(buyData.buyAddr) == ethAddr;
		convertWethToEth(isEth, _buyAddr, _buyAmt);

		setUint(setId, _sellAmt);

		_eventName = "LogBuy(address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			buyData.buyAddr,
			buyData.sellAddr,
			_buyAmt,
			_sellAmt,
			getId,
			setId
		);
	}

	/**
	 * @dev Sell Function
	 * @notice Swap token(sellAddr) with token(buyAddr), to get max buy tokens
	 * @param sellData Data input for the sell action
	 * @param getId Id to get buyAmt
	 * @param setId Id to store sellAmt
	 */
	function _sell(
		SellInfo memory sellData,
		uint256 getId,
		uint256 setId
	) internal returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _sellAmt = getUint(getId, sellData.sellAmt);
		(TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(
			sellData.buyAddr,
			sellData.sellAddr
		);

		if (_sellAmt == uint256(-1)) {
			_sellAmt = sellData.sellAddr == ethAddr
				? address(this).balance
				: _sellAddr.balanceOf(address(this));
		}

		uint256 _slippageAmt = convert18ToDec(
			_buyAddr.decimals(),
			wmul(sellData.unitAmt, convertTo18(_sellAddr.decimals(), _sellAmt))
		);

		bool isEth = address(sellData.sellAddr) == ethAddr;
		convertEthToWeth(isEth, _sellAddr, _sellAmt);
		approve(_sellAddr, address(swapRouter), _sellAmt);
		ExactInputSingleParams memory params = ExactInputSingleParams({
			tokenIn: address(_sellAddr),
			tokenOut: address(_buyAddr),
			fee: sellData.fee,
			recipient: address(this),
			amountIn: _sellAmt,
			amountOutMinimum: _slippageAmt, //require(_buyAmt >= amountOutMinimum)
			sqrtPriceLimitX96: 0
		});

		uint256 _buyAmt = swapRouter.exactInputSingle(params);
		require(_slippageAmt <= _buyAmt, "Too much slippage");

		isEth = address(sellData.buyAddr) == ethAddr;
		convertWethToEth(isEth, _buyAddr, _buyAmt);

		setUint(setId, _buyAmt);

		_eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			sellData.buyAddr,
			sellData.sellAddr,
			_buyAmt,
			_sellAmt,
			getId,
			setId
		);
	}
}
