//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "./interfaces.sol";
import { Stores } from "./stores.sol";
import { DSMath } from "./math.sol";

abstract contract Basic is DSMath, Stores {
	function convert18ToDec(uint256 _dec, uint256 _amt)
		internal
		pure
		returns (uint256 amt)
	{
		amt = (_amt / 10**(18 - _dec));
	}

	function convertTo18(uint256 _dec, uint256 _amt)
		internal
		pure
		returns (uint256 amt)
	{
		amt = mul(_amt, 10**(18 - _dec));
	}

	function getTokenBal(TokenInterface token)
		internal
		view
		returns (uint256 _amt)
	{
		_amt = address(token) == ftmAddr
			? address(this).balance
			: token.balanceOf(address(this));
	}

	function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr)
		internal
		view
		returns (uint256 buyDec, uint256 sellDec)
	{
		buyDec = address(buyAddr) == ftmAddr ? 18 : buyAddr.decimals();
		sellDec = address(sellAddr) == ftmAddr ? 18 : sellAddr.decimals();
	}

	function encodeEvent(string memory eventName, bytes memory eventParam)
		internal
		pure
		returns (bytes memory)
	{
		return abi.encode(eventName, eventParam);
	}

	function approve(
		TokenInterface token,
		address spender,
		uint256 amount
	) internal {
		try token.approve(spender, amount) {} catch {
			token.approve(spender, 0);
			token.approve(spender, amount);
		}
	}

	function changeftmAddress(address buy, address sell)
		internal
		pure
		returns (TokenInterface _buy, TokenInterface _sell)
	{
		_buy = buy == ftmAddr ? TokenInterface(wftmAddr) : TokenInterface(buy);
		_sell = sell == ftmAddr
			? TokenInterface(wftmAddr)
			: TokenInterface(sell);
	}

	function convertFtmToWftm(
		bool isFtm,
		TokenInterface token,
		uint256 amount
	) internal {
		if (isFtm) token.deposit{ value: amount }();
	}

	function convertWftmToFtm(
		bool isFtm,
		TokenInterface token,
		uint256 amount
	) internal {
		if (isFtm) {
			approve(token, address(token), amount);
			token.withdraw(amount);
		}
	}
}
