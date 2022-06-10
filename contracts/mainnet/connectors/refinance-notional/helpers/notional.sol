//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { Helpers } from "../helpers.sol";
import { Token, NotionalInterface, BalanceAction, BalanceActionWithTrades, DepositActionType, AaveV2DataProviderInterface } from "../interface.sol";

contract NotionalHelpers is Helpers {
	function _notionalBorrowOne(
		uint256 fee,
		bool redeemToUnderlying,
		uint256 fCashAmount,
		uint256 maxBorrowRate,
		uint16 currencyID,
		uint256 marketIndex
	) internal {
		//collateral should be depositied beforehand in other currency
		BalanceActionWithTrades[]
			memory actions = new BalanceActionWithTrades[](1);
		bytes32[] memory trades = new bytes32[](1);
		trades[0] = encodeBorrowTrade(marketIndex, fCashAmount, maxBorrowRate);

		actions[0].actionType = DepositActionType.None;
		actions[0].currencyId = currencyID;
		actions[0].withdrawEntireCashBalance = true;
		actions[0].depositActionAmount = 0;
		actions[0].redeemToUnderlying = redeemToUnderlying;
		actions[0].trades = trades;

		notional.batchBalanceAndTradeAction(address(this), actions);
	}

	/// @return finalAmts payback amount on Aave
	function _notionalBorrow(NotionalBorrowData memory data)
		internal
		returns (uint256[] memory)
	{
		uint256[] memory finalAmts = new uint256[](data.length);
		for (uint256 i = 0; i < data.length; i++) {
			uint16 _currencyID = toUint16(data.currencyIDs[i]);
			uint256 _amt = data.amts[i];

			//borrow token on Notional
			_notionalBorrowOne(
				data.fee,
				data.redeemToUnderlying[i],
				data.fCashAmount[i],
				data.maxBorrowRate[i],
				_currencyID,
				data.marketIndex[i]
			);

			//calculating payback amounts for Aave v2
			if (_amt == uint256(-1)) {
				_amt = getAaveV2PaybackAmt(data.rateModes[i], data.tokens[i]);
			}
			finalAmts[i] = _amt;

			//calculate and transferFees
			calculateAndTransferFees(data.tokens[i], _amt, data.fee, true);
		}
	}

	// deposit as collateral i.e. reduces the risk of liquidation or mint ntokens i.e. provides liquidity, this method doesn't lends to the market at fixed rate
	function _notionalDepositOne(
		uint256 fee,
		uint256 amt,
		address token,
		bool mintNToken,
		uint16 currencyID
	) internal {
		if (amt > 0) {
			(uint256 feeAmt, uint256 depositAmount) = calculateFee(
				amt,
				fee,
				false
			);

			token = (token == wethAddr) ? ethAddr : token;
			transferFees(token, feeAmt);

			if (mintNToken) {
				//deposit cash and mint nTokens
				BalanceAction[] memory action = new BalanceAction[](1);
				action[0].actionType = DepositActionType
					.DepositUnderlyingAndMintNToken;
				action[0].currencyId = toUint16(currencyID);
				action[0].depositActionAmount = depositAmount;

				if (currencyID == ETH_CURRENCY_ID) {
					notional.batchBalanceAction{ value: depositAmount }(
						address(this),
						action
					);
				} else {
					notional.batchBalanceAction(address(this), action);
				}
			} else {
				//deposit as collateral
				if (currencyID == ETH_CURRENCY_ID) {
					notional.depositUnderlyingToken{ value: depositAmount }(
						address(this),
						currencyID,
						depositAmount
					);
				} else {
					notional.depositAssetToken(
						address(this),
						currencyID,
						depositAmount
					);
				}
			}
		}
	}

	// deposits on notional
	function _notionalDeposit(
		uint256 length,
		uint256 fee,
		uint256[] memory currencyIDs,
		uint256[] memory amts,
		address[] memory tokens,
		bool[] memory mintNTokens
	) internal {
		for (uint256 i = 0; i < length; i++) {
			_notionalDepositOne(
				fee,
				amts[i],
				tokens[i],
				mintNTokens[i],
				toUint16(currencyIDs[i])
			);
		}
	}
}
