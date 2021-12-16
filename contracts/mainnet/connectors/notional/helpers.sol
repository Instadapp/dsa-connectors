pragma solidity ^0.7.6;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Token, NotionalInterface, BalanceAction, BalanceActionWithTrades} from "./interface.sol";
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

    NotionalInterface internal constant notional =
        NotionalInterface(0x1344A36A1B56144C3Bc62E7757377D288fDE0369);

    function getUnderlyingToken(uint16 currencyId) internal returns (address) {
        (, Token memory underlyingToken) = notional.getCurrency(currencyId);
        return underlyingToken.tokenAddress;
    }

    function getAssetToken(uint16 currencyId) internal returns (address) {
        (Token memory assetToken, ) = notional.getCurrency(currencyId);
        return assetToken.tokenAddress;
    }

    function getCashBalance(uint16 currencyId)
        internal
        returns (int256 cashBalance)
    {
        (cashBalance, , ) = notional.getAccountBalance(
            currencyId,
            address(this)
        );
    }

    function getNTokenBalance(uint16 currencyId)
        internal
        returns (int256 nTokenBalance)
    {
        (, nTokenBalance, ) = notional.getAccountBalance(
            currencyId,
            address(this)
        );
    }

    function convertToInternal(uint16 currencyId, int256 amount)
        internal
        returns (int256)
    {
        // If token decimals is greater than INTERNAL_TOKEN_PRECISION then this will truncate
        // down to the internal precision. Resulting dust will accumulate to the protocol.
        // If token decimals is less than INTERNAL_TOKEN_PRECISION then this will add zeros to the
        // end of amount and will not result in dust.
        (Token memory assetToken, ) = notional.getCurrency(currencyId);
        if (assetToken.decimals == INTERNAL_TOKEN_PRECISION) return amount;
        return amount.mul(INTERNAL_TOKEN_PRECISION).div(assetToken.decimals);
    }

    function encodeLendTrade(
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 minLendRate
    ) internal returns (bytes32) {
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
    ) internal returns (bytes32) {
        return
            (bytes32(uint256(BORROW_TRADE)) << 248) |
            (bytes32(uint256(marketIndex)) << 240) |
            (bytes32(uint256(fCashAmount)) << 152) |
            (bytes32(uint256(maxBorrowRate)) << 120);
    }

    function getDepositAmountAndSetApproval(
        uint256 getId,
        uint16 currencyId,
        bool useUnderlying,
        uint256 depositAmount
    ) internal returns (uint256) {
        depositAmount = getUint(getId, depositAmount);
        if (currencyId == ETH_CURRENCY_ID && useUnderlying)
            return
                depositAmount == uint256(-1)
                    ? address(this).balance
                    : depositAmount;

        address tokenAddress = useUnderlying
            ? getUnderlyingToken(currencyId)
            : getAssetToken(currencyId);
        if (depositAmount == uint256(-1)) {
            depositAmount = TokenInterface(tokenAddress).balanceOf(
                address(this)
            );
        }
        approve(TokenInterface(tokenAddress), address(notional), depositAmount);
        return depositAmount;
    }

    function getBalance(address addr) internal returns (uint256) {
        if (addr == ethAddr) {
            return address(this).balance;
        }

        return TokenInterface(addr).balanceOf(address(this));
    }

    function getAddress(uint16 currencyId, bool useUnderlying)
        internal
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
}
