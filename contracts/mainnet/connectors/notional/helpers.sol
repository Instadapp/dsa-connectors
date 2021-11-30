pragma solidity ^0.7.6;
pragma abicoder v2;

import {Token, NotionalInterface} from "./interface.sol";
import {Basic} from "../../common/basic.sol";

contract Helpers is Basic {
    uint8 internal constant LEND_TRADE = 0;
    uint8 internal constant BORROW_TRADE = 1;
    int256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;
    uint256 internal constant ETH_CURRENCY_ID = 1;
    int256 private constant _INT256_MIN = type(int256).min;

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
        return div(mul(amount, INTERNAL_TOKEN_PRECISION), assetToken.decimals);
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

    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        c = a * b;
        if (a == -1) require(b == 0 || c / b == a);
        else require(a == 0 || c / a == b);
    }

    function div(int256 a, int256 b) internal pure returns (int256 c) {
        require(!(b == -1 && a == _INT256_MIN)); // dev: int256 div overflow
        // NOTE: solidity will automatically revert on divide by zero
        c = a / b;
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        //  taken from uniswap v3
        require((z = x - y) <= x == (y >= 0));
    }

    //function getDepositAmountAndSetApproval(uint16 currencyId) internal;

    //function executeActionWithBalanceChange(uint16 currencyId) internal;
}
