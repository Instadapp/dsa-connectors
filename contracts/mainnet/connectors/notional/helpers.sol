pragma solidity ^0.7.6;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Token, NotionalInterface, BalanceAction, BalanceActionWithTrades, DepositActionType} from "./interface.sol";
import {SafeInt256} from "./SafeInt256.sol";
import {Basic} from "../../common/basic.sol";
import {TokenInterface} from "../../common/interfaces.sol";

contract Helpers is Basic {
    using SafeMath for uint256;
    using SafeInt256 for int256;
    uint8 internal constant LEND_TRADE = 0;
    uint8 internal constant BORROW_TRADE = 1;
    int256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;
    uint256 internal constant ETH_CURRENCY_ID = 1;
    uint256 internal constant MAX_DEPOSIT = uint256(-1);

    /// @dev Contract address is different on Kovan: 0x0EAE7BAdEF8f95De91fDDb74a89A786cF891Eb0e
    NotionalInterface internal constant notional =
        NotionalInterface(0x1344A36A1B56144C3Bc62E7757377D288fDE0369);

    /// @notice Returns the address of the underlying token for a given currency id, 
    function getUnderlyingToken(uint16 currencyId) internal view returns (address) {
        (
            /* Token memory assetToken */,
            Token memory underlyingToken
        ) = notional.getCurrency(currencyId);
        return underlyingToken.tokenAddress;
    }

    /// @notice Returns the address of the asset token for a given currency id
    function getAssetToken(uint16 currencyId) internal view returns (address) {
        (
            Token memory assetToken,
            /* Token memory underlyingToken */
        ) = notional.getCurrency(currencyId);
        return assetToken.tokenAddress;
    }

    function getCashBalance(uint16 currencyId) internal view returns (int256 cashBalance) {
        (
            cashBalance,
            /* int256 nTokenBalance */,
            /* int256 lastClaimTime */
        ) = notional.getAccountBalance(currencyId, address(this));
    }

    function getNTokenBalance(uint16 currencyId) internal view returns (int256 nTokenBalance) {
        (
            /* int256 cashBalance */,
            nTokenBalance,
            /* int256 lastClaimTime */
        ) = notional.getAccountBalance(currencyId, address(this));
    }

    function getNTokenRedeemAmount(uint16 currencyId, uint96 _tokensToRedeem, uint256 getId)
        internal
        returns (uint96 tokensToRedeem) {
        tokensToRedeem = uint96(getUint(getId, _tokensToRedeem));
        if (tokensToRedeem == uint96(-1)) {
            tokensToRedeem = uint96(getNTokenBalance(currencyId));
        }
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

    function convertToInternal(uint16 currencyId, int256 amount)
        internal view
        returns (int256)
    {
        // If token decimals is greater than INTERNAL_TOKEN_PRECISION then this will truncate
        // down to the internal precision. Resulting dust will accumulate to the protocol.
        // If token decimals is less than INTERNAL_TOKEN_PRECISION then this will add zeros to the
        // end of amount and will not result in dust.
        (Token memory assetToken, /* underlyingToken */) = notional.getCurrency(currencyId);
        if (assetToken.decimals == INTERNAL_TOKEN_PRECISION) return amount;
        return amount.mul(INTERNAL_TOKEN_PRECISION).div(assetToken.decimals);
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
            return depositAmount == MAX_DEPOSIT
                ? address(this).balance
                : depositAmount;
        }

        address tokenAddress = useUnderlying
            ? getUnderlyingToken(currencyId)
            : getAssetToken(currencyId);

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

        return
            useUnderlying
                ? getUnderlyingToken(currencyId)
                : getAssetToken(currencyId);
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

        notional.batchBalanceAndTradeAction{value: msgValue}(
            address(this),
            action
        );

        if (setId != 0) {
            uint256 balanceAfter = getBalance(tokenAddress);
            setUint(setId, balanceAfter.sub(balanceBefore));
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

        notional.batchBalanceAction{value: msgValue}(address(this), action);

        if (setId != 0) {
            uint256 balanceAfter = getBalance(tokenAddress);
            setUint(setId, balanceAfter.sub(balanceBefore));
        }
    }

    function getDepositCollateralBorrowAndWithdrawActions(
        uint16 depositCurrencyId,
        bool useUnderlying,
        uint256 depositAmount,
        uint16 borrowCurrencyId,
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 maxBorrowRate,
        bool redeemToUnderlying
    ) internal returns (BalanceActionWithTrades[] memory action) {
        // TODO: allow minting nTokens here....
        BalanceActionWithTrades[]
            memory actions = new BalanceActionWithTrades[](2);

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

        actions[depositIndex].actionType = useUnderlying
            ? DepositActionType.DepositUnderlying
            : DepositActionType.DepositAsset;
        actions[depositIndex].currencyId = depositCurrencyId;
        actions[depositIndex].depositActionAmount = depositAmount;

        actions[borrowIndex].actionType = DepositActionType.None;
        actions[borrowIndex].currencyId = borrowCurrencyId;
        // Withdraw borrowed amount to wallet
        actions[borrowIndex].withdrawEntireCashBalance = true;
        actions[borrowIndex].redeemToUnderlying = redeemToUnderlying;

        bytes32[] memory trades = new bytes32[](1);
        trades[0] = encodeBorrowTrade(marketIndex, fCashAmount, maxBorrowRate);
        actions[borrowIndex].trades = trades;

        return actions;
    }

}
