//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { CometInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	struct BorrowWithdrawParams {
		address market;
		address token;
		address from;
		address to;
		uint256 amt;
		uint256 getId;
		uint256 setId;
	}

	function getBaseToken(address market)
		internal
		view
		returns (address baseToken)
	{
		baseToken = CometInterface(market).baseToken();
	}

	/**
	 *@dev helper function for three withdraw or borrow cases:
	 *withdraw - for `withdraw` withdraws the collateral or base from DSA's position to account.
	 *withdrawFrom - for `withdrawFromUsingManager` withdraws from src to dest using DSA as manager
	 *withdrawTo - for `withdrawTo` withdraws from DSA to dest address.
	 */
	function _withdrawHelper(
		address market,
		address token,
		address from,
		address to,
		uint256 amt
	) internal {
		if (from == address(0)) {
			CometInterface(market).withdrawTo(to, token, amt);
		} else if (from != address(0) && to != address(0)) {
			CometInterface(market).withdrawFrom(from, to, token, amt);
		}
	}

	function _borrow(BorrowWithdrawParams memory params)
		internal
		returns (uint256 amt, uint256 setId)
	{
		uint256 amt_ = getUint(params.getId, params.amt);

		require(
			params.market != address(0) && params.token != address(0),
			"invalid market/token address"
		);
		bool isEth = params.token == ethAddr;
		address token_ = isEth ? wethAddr : params.token;

		TokenInterface tokenContract = TokenInterface(token_);

		params.from = params.from == address(0) ? address(this) : params.from;
		uint256 initialBal = CometInterface(params.market).borrowBalanceOf(
			params.from
		);

		uint256 balance = TokenInterface(params.market).balanceOf(params.from);
		require(balance == 0, "borrow-disabled-when-supplied-base");

		_withdrawHelper(params.market, token_, params.from, params.to, amt_);

		uint256 finalBal = CometInterface(params.market).borrowBalanceOf(
			params.from
		);
		amt_ = sub(finalBal, initialBal);

		if (params.from == address(0) || params.to == address(this))
			convertWethToEth(isEth, tokenContract, amt_);

		setUint(params.setId, amt_);

		amt = amt_;
		setId = params.setId;
	}

	function _withdraw(BorrowWithdrawParams memory params)
		internal
		returns (uint256 amt, uint256 setId)
	{
		uint256 amt_ = getUint(params.getId, params.amt);

		require(
			params.market != address(0) && params.token != address(0),
			"invalid market/token address"
		);

		bool isEth = params.token == ethAddr;
		address token_ = isEth ? wethAddr : params.token;

		TokenInterface tokenContract = TokenInterface(token_);
		params.from = params.from == address(0) ? address(this) : params.from;

		uint256 initialBal = getAccountSupplyBalanceOfAsset(
			params.from,
			params.market,
			token_
		);
		amt_ = amt_ == uint256(-1) ? initialBal : amt_;

		if (token_ == getBaseToken(params.market)) {
			uint256 balance = TokenInterface(params.market).balanceOf(
				params.from
			);
			if (balance > 0) {
				require(amt_ <= balance, "withdraw-amt-greater-than-supplies");
			}
		}

		_withdrawHelper(params.market, token_, params.from, params.to, amt_);

		uint256 finalBal = getAccountSupplyBalanceOfAsset(
			params.from,
			params.market,
			token_
		);
		amt_ = sub(initialBal, finalBal);

		if (params.from == address(0) || params.to == address(this))
			convertWethToEth(isEth, tokenContract, amt_);

		setUint(params.setId, amt_);

		amt = amt_;
		setId = params.setId;
	}

	function _transfer(
		address market,
		address token,
		address from,
		address to,
		uint256 amt
	) internal {
		if (from == address(0)) {
			CometInterface(market).transferAsset(to, token, amt);
		} else {
			CometInterface(market).transferAssetFrom(from, to, token, amt);
		}
	}

	function getAccountSupplyBalanceOfAsset(
		address account,
		address market,
		address asset
	) internal returns (uint256 balance) {
		if (asset == getBaseToken(market)) {
			//balance in base
			balance = TokenInterface(market).balanceOf(account);
		} else {
			//balance in asset denomination
			balance = uint256(
				CometInterface(market).userCollateral(account, asset).balance
			);
		}
	}

	function setAmt(
		address market,
		address token,
		address src,
		uint256 amt,
		bool isEth,
		bool isRepay
	) internal returns (uint256) {
		if (isEth) {
			if (amt == uint256(-1)) {
				uint256 allowance_ = TokenInterface(token).allowance(
					src,
					market
				);
				uint256 bal_;
				if (isRepay) {
					bal_ = CometInterface(market).borrowBalanceOf(src);
				} else {
					bal_ = src.balance;
				}
				amt = bal_ < allowance_ ? bal_ : allowance_;
			}
			if (src == address(this))
				convertEthToWeth(isEth, TokenInterface(token), amt);
		} else {
			if (amt == uint256(-1)) {
				uint256 allowance_ = TokenInterface(token).allowance(
					src,
					market
				);
				uint256 bal_;
				if (isRepay) {
					bal_ = (token == getBaseToken(market))
						? CometInterface(market).borrowBalanceOf(src)
						: CometInterface(market)
							.userCollateral(src, token)
							.balance;
				} else {
					bal_ = (token == getBaseToken(market))
						? TokenInterface(market).balanceOf(src)
						: CometInterface(market)
							.userCollateral(src, token)
							.balance;
				}

				amt = bal_ < allowance_ ? bal_ : allowance_;
			}
		}
		return amt;
	}
}
