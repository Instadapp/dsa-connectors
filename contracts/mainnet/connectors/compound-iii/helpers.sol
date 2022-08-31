//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { CometInterface, CometRewards } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	CometRewards internal constant cometRewards =
		CometRewards(0x1B0e765F6224C21223AeA2af16c1C46E38885a40);

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

	function _withdraw(
		address market,
		address token,
		address from,
		address to,
		uint256 amt
	) internal {

		if (from == address(0) && to == address(0)) {
			CometInterface(market).withdraw(token, amt);
		} else if (from == address(0)) {
			CometInterface(market).withdrawTo(to, token, amt);
		} else if (from != address(0) && to != address(0)) {
			CometInterface(market).withdrawFrom(from, to, token, amt);
		}
	}

	function _transfer(
		address market,
		address token,
		address from,
		address to,
		uint256 amt
	) internal {
		bytes memory data;

		if (from == address(0)) {
			CometInterface(market).transferAsset(to, token, amt);
		} else {
			CometInterface(market).transferAssetFrom(from, to, token, amt);
		}
	}

	function _borrowOrWithdraw(BorrowWithdrawParams memory params)
		internal
		returns (uint256 amt, uint256 setId)
	{
		uint256 _amt = getUint(params.getId, params.amt);

		require(
			params.market != address(0) && params.token != address(0),
			"invalid market/token address"
		);
		bool isEth = params.token == ethAddr;
		address _token = isEth ? wethAddr : params.token;

		TokenInterface tokenContract = TokenInterface(_token);

		uint256 initialBal = getAccountSupplyBalanceOfAsset(
			address(this),
			params.market,
			_token
		);

		_amt = _amt == uint256(-1) ? initialBal : _amt;

		_withdraw(params.market, _token, params.from, params.to, _amt);

		uint256 finalBal = getAccountSupplyBalanceOfAsset(
			address(this),
			params.market,
			_token
		);
		_amt = sub(finalBal, initialBal);

		convertWethToEth(isEth, tokenContract, _amt);

		setUint(params.setId, _amt);

		amt = _amt;
		setId = params.setId;
	}

	function getAccountSupplyBalanceOfAsset(
		address account,
		address market,
		address asset
	) internal returns (uint256 balance) {
		if (asset == getBaseToken(market)) {
			//balance in base
			balance = CometInterface(market).balanceOf(account);
		} else {
			//balance in asset denomination
			balance = uint256(
				CometInterface(market).userCollateral(account, asset).balance
			);
		}
	}
}
