// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { Token, NotionalInterface, StakingInterface, BalanceAction, BalanceActionWithTrades, DepositActionType } from "./interface.sol";
import { Basic } from "../../common/basic.sol";
import { DSMath } from "../../common/math.sol";
import { TokenInterface } from "../../common/interfaces.sol";

abstract contract Helpers is DSMath, Basic {
	uint8 internal constant LEND_TRADE = 0;
	uint8 internal constant BORROW_TRADE = 1;
	uint256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;
	uint256 internal constant ETH_CURRENCY_ID = 1;
	uint256 internal constant MAX_DEPOSIT = type(uint256).max;

	/// @dev Contract address is different on Kovan: 0x0EAE7BAdEF8f95De91fDDb74a89A786cF891Eb0e
	NotionalInterface internal constant notional =
		NotionalInterface(0x1344A36A1B56144C3Bc62E7757377D288fDE0369);

	/// @dev sNOTE contract address
	StakingInterface internal constant staking =
		StakingInterface(0x38DE42F4BA8a35056b33A746A6b45bE9B1c3B9d2);

	/// @dev sNOTE balancer pool token address
	TokenInterface internal constant bpt =
		TokenInterface(0x5122E01D819E58BB2E22528c0D68D310f0AA6FD7);

	/// @dev NOTE token address
	TokenInterface internal constant note =
		TokenInterface(0xCFEAead4947f0705A14ec42aC3D44129E1Ef3eD5);

	/// @dev WETH token address
	TokenInterface internal constant weth =
		TokenInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

	/// @notice Returns the address of the underlying token for a given currency id,
	function getAssetOrUnderlyingToken(uint16 currencyId, bool underlying)
		internal
		view
		returns (address)
	{
		// prettier-ignore
		(Token memory assetToken, Token memory underlyingToken) = notional.getCurrency(currencyId);
		return
			underlying ? underlyingToken.tokenAddress : assetToken.tokenAddress;
	}

	function getCashOrNTokenBalance(uint16 currencyId, bool nToken)
		internal
		view
		returns (uint256)
	{
		// prettier-ignore
		(
            int256 cashBalance,
            int256 nTokenBalance,
            /* int256 lastClaimTime */
        ) = notional.getAccountBalance(currencyId, address(this));
		return toUint(nToken ? nTokenBalance : cashBalance);
	}

	function getNTokenRedeemAmount(
		uint16 currencyId,
		uint96 _tokensToRedeem,
		uint256 getId
	) internal returns (uint96 tokensToRedeem) {
		tokensToRedeem = toUint96(getUint(getId, _tokensToRedeem));
		if (tokensToRedeem == type(uint96).max) {
			tokensToRedeem = toUint96(getCashOrNTokenBalance(currencyId, true));
		}
	}

	function toUint96(uint256 value) internal pure returns (uint96) {
		require(value <= type(uint96).max, "uint96 value overflow");
		return uint96(value);
	}

	function toUint88(uint256 value) internal pure returns (uint88) {
		require(value <= type(uint88).max, "uint88 value overflow");
		return uint88(value);
	}

	function getMsgValue(
		uint16 currencyId,
		bool useUnderlying,
		uint256 depositAmount
	) internal pure returns (uint256 msgValue) {
		msgValue = (currencyId == ETH_CURRENCY_ID && useUnderlying)
			? depositAmount
			: 0;
	}

	function convertToInternal(uint16 currencyId, uint256 amount)
		internal
		view
		returns (uint256)
	{
		// If token decimals is greater than INTERNAL_TOKEN_PRECISION then this will truncate
		// down to the internal precision. Resulting dust will accumulate to the protocol.
		// If token decimals is less than INTERNAL_TOKEN_PRECISION then this will add zeros to the
		// end of amount and will not result in dust.
		// prettier-ignore
		(Token memory assetToken, /* underlyingToken */) = notional.getCurrency(currencyId);
		uint256 decimals = toUint(assetToken.decimals);
		if (decimals == INTERNAL_TOKEN_PRECISION) return amount;
		return div(mul(amount, INTERNAL_TOKEN_PRECISION), decimals);
	}

	function encodeLendTrade(
		uint8 marketIndex,
		uint88 fCashAmount,
		uint32 minLendRate
	) internal pure returns (bytes32) {
		return
			(bytes32(uint256(LEND_TRADE)) << 248) |
			(bytes32(uint256(marketIndex)) << 240) |
			(bytes32(uint256(fCashAmount)) << 152) |
			(bytes32(uint256(minLendRate)) << 120);
	}

	function encodeBorrowTrade(
		uint8 marketIndex,
		uint88 fCashAmount,
		uint32 maxBorrowRate
	) internal pure returns (bytes32) {
		return
			(bytes32(uint256(BORROW_TRADE)) << 248) |
			(bytes32(uint256(marketIndex)) << 240) |
			(bytes32(uint256(fCashAmount)) << 152) |
			(bytes32(uint256(maxBorrowRate)) << 120);
	}

	/// @dev Uses getId to set approval for the given token up to the specified deposit
	/// amount only
	function getDepositAmountAndSetApproval(
		uint256 getId,
		uint16 currencyId,
		bool useUnderlying,
		uint256 depositAmount
	) internal returns (uint256) {
		depositAmount = getUint(getId, depositAmount);
		if (currencyId == ETH_CURRENCY_ID && useUnderlying) {
			// No approval required for ETH so we can return the deposit amount
			return
				depositAmount == MAX_DEPOSIT
					? address(this).balance
					: depositAmount;
		}

		address tokenAddress = getAssetOrUnderlyingToken(
			currencyId,
			useUnderlying
		);

		if (depositAmount == MAX_DEPOSIT) {
			depositAmount = TokenInterface(tokenAddress).balanceOf(
				address(this)
			);
		}
		approve(TokenInterface(tokenAddress), address(notional), depositAmount);
		return depositAmount;
	}

	function getBalance(address addr) internal view returns (uint256) {
		if (addr == ethAddr) {
			return address(this).balance;
		}

		return TokenInterface(addr).balanceOf(address(this));
	}

	function getAddress(uint16 currencyId, bool useUnderlying)
		internal
		view
		returns (address)
	{
		if (currencyId == ETH_CURRENCY_ID && useUnderlying) {
			return ethAddr;
		}

		return getAssetOrUnderlyingToken(currencyId, useUnderlying);
	}

	/// @dev Executes a trade action and sets the balance change to setId
	function executeTradeActionWithBalanceChange(
		BalanceActionWithTrades[] memory action,
		uint256 msgValue,
		uint16 currencyId,
		bool useUnderlying,
		uint256 setId
	) internal {
		address tokenAddress;
		uint256 balanceBefore;
		if (setId != 0) {
			tokenAddress = getAddress(currencyId, useUnderlying);
			balanceBefore = getBalance(tokenAddress);
		}

		notional.batchBalanceAndTradeAction{ value: msgValue }(
			address(this),
			action
		);

		if (setId != 0) {
			uint256 balanceAfter = getBalance(tokenAddress);
			setUint(setId, sub(balanceAfter, balanceBefore));
		}
	}

	/// @dev Executes a balance action and sets the balance change to setId
	function executeActionWithBalanceChange(
		BalanceAction[] memory action,
		uint256 msgValue,
		uint16 currencyId,
		bool useUnderlying,
		uint256 setId
	) internal {
		address tokenAddress;
		uint256 balanceBefore;
		if (setId != 0) {
			tokenAddress = getAddress(currencyId, useUnderlying);
			balanceBefore = getBalance(tokenAddress);
		}

		notional.batchBalanceAction{ value: msgValue }(address(this), action);

		if (setId != 0) {
			uint256 balanceAfter = getBalance(tokenAddress);
			setUint(setId, sub(balanceAfter, balanceBefore));
		}
	}

	function getDepositCollateralBorrowAndWithdrawActions(
		uint16 depositCurrencyId,
		DepositActionType depositAction,
		uint256 depositAmount,
		uint16 borrowCurrencyId,
		uint8 marketIndex,
		uint88 fCashAmount,
		uint32 maxBorrowRate,
		bool redeemToUnderlying
	) internal returns (BalanceActionWithTrades[] memory action) {
		BalanceActionWithTrades[] memory actions;
		bytes32[] memory trades = new bytes32[](1);
		trades[0] = encodeBorrowTrade(marketIndex, fCashAmount, maxBorrowRate);

		if (depositCurrencyId == borrowCurrencyId) {
			// In this case the account is likely borrowing against newly minted nTokens
			// in the same currency. Technically the other deposit actions may work but
			// there's no good reason to borrow against cToken collateral
			actions = new BalanceActionWithTrades[](1);
			actions[0].actionType = depositAction;
			actions[0].currencyId = depositCurrencyId;
			actions[0].depositActionAmount = depositAmount;
			// Withdraw borrowed amount to wallet
			actions[0].withdrawEntireCashBalance = true;
			actions[0].redeemToUnderlying = redeemToUnderlying;
			actions[0].trades = trades;

			return actions;
		}

		// This is the more common case that the account is borrowing against
		// collateral in a different currency
		actions = new BalanceActionWithTrades[](2);

		uint256 depositIndex;
		uint256 borrowIndex;
		// Notional requires the batch actions to be ordered by currency id
		if (depositCurrencyId < borrowCurrencyId) {
			depositIndex = 0;
			borrowIndex = 1;
		} else {
			depositIndex = 1;
			borrowIndex = 0;
		}

		actions[depositIndex].actionType = depositAction;
		actions[depositIndex].currencyId = depositCurrencyId;
		actions[depositIndex].depositActionAmount = depositAmount;

		actions[borrowIndex].actionType = DepositActionType.None;
		actions[borrowIndex].currencyId = borrowCurrencyId;
		// Withdraw borrowed amount to wallet
		actions[borrowIndex].withdrawEntireCashBalance = true;
		actions[borrowIndex].redeemToUnderlying = redeemToUnderlying;
		actions[borrowIndex].trades = trades;

		return actions;
	}
}
