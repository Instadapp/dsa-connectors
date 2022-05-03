// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Uniswap v3 swap.
 * @dev Decentralized Exchange.
 */

import { TokenInterface } from "../../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import "./interface.sol";

abstract contract UniswapResolver is Helpers, Events {
	/**
	 * @dev Buy Function
	 * @notice Swap token(sellAddr) with token(buyAddr), buy token with minimum sell token
	 * @param _buyAddr token to be bought
	 * @param _sellAddr token to be sold
	 * @param _fee pool fees for buyAddr-sellAddr token pair
	 * @param _unitAmt The unit amount of sellAmt/buyAmt with slippage
	 * @param _buyAmt amount of token to be bought
	 * @param _getId Id to get buyAmt
	 * @param _setId Id to store sellAmt
	 */
	function buy(
		address _buyAddr,
		address _sellAddr,
		uint24 _fee,
		uint256 _unitAmt,
		uint256 _buyAmt,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		return
			_buy(
				BuyInfo({
					buyAddr: _buyAddr,
					sellAddr: _sellAddr,
					fee: _fee,
					unitAmt: _unitAmt,
					buyAmt: _buyAmt
				}),
				_getId,
				_setId
			);
	}

	/**
	 * @dev Sell Function
	 * @notice Swap token(sellAddr) with token(buyAddr), buy token with minimum sell token
	 * @param _buyAddr token to be bought
	 * @param _sellAddr token to be sold
	 * @param _fee pool fees for buyAddr-sellAddr token pair
	 * @param _unitAmt The unit amount of buyAmt/sellAmt with slippage
	 * @param _sellAmt amount of token to be sold
	 * @param _getId Id to get sellAmt
	 * @param _setId Id to store buyAmt
	 */
	function sell(
		address _buyAddr,
		address _sellAddr,
		uint24 _fee,
		uint256 _unitAmt,
		uint256 _sellAmt,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		return
			_sell(
				SellInfo({
					buyAddr: _buyAddr,
					sellAddr: _sellAddr,
					fee: _fee,
					unitAmt: _unitAmt,
					sellAmt: _sellAmt
				}),
				_getId,
				_setId
			);
	}
}

contract ConnectV2UniswapV3SwapOptimism is UniswapResolver {
	string public constant name = "UniswapV3-Swap-v1";
}
