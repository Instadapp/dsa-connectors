// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract Events {
    event LogDepositCollateral(
        address indexed account,
        uint16 currencyId,
        bool isUnderlying,
        uint256 depositAmount,
        uint256 assetCashDeposited
    );

    event LogWithdrawCollateral(
        address indexed account,
        uint16 currencyId,
        bool isUnderlying,
        uint256 amountWithdrawn
    );

    event LogClaimNOTE(address indexed account, uint256 notesClaimed);

    event LogRedeemNTokenRaw(
        address indexed account,
        uint16 currencyId,
        bool sellTokenAssets,
        uint96 tokensToRedeem,
        int256 assetCashChange
    );

    event LogRedeemNTokenWithdraw(
        address indexed account,
        uint16 currencyId,
        uint96 tokensToRedeem,
        uint256 amountToWithdraw,
        bool redeemToUnderlying
    );

    event LogRedeemNTokenAndDeleverage(
        address indexed account,
        uint16 currencyId,
        uint96 tokensToRedeem,
        uint8 marketIndex,
        uint88 fCashAmount
    );

    event LogDepositAndMintNToken(
        address indexed account,
        uint16 currencyId,
        bool isUnderlying,
        uint256 depositAmount,
        int256 nTokenBalanceChange
    );

    event LogMintNTokenFromCash(
        address indexed account,
        uint16 currencyId,
        uint256 cashBalanceToMint,
        int256 nTokenBalanceChange
    );

    event LogDepositAndLend(
        address indexed account,
        uint16 currencyId,
        bool isUnderlying,
        uint256 depositAmount,
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 minLendRate
    );

    event LogDepositCollateralBorrowAndWithdraw(
        address indexed account,
        bool useUnderlying,
        uint256 depositAmount,
        uint16 borrowCurrencyId,
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 maxBorrowRate,
        bool redeemToUnderlying
    );

    event LogWithdrawLend(
        address indexed account,
        uint16 currencyId,
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 maxBorrowRate
    );

    event LogBatchActionRaw(address indexed account);

    event LogMintSNoteFromBPT(address indexed account, uint256 bptAmount);

    event LogMintSNoteFromETH(
        address indexed account,
        uint256 noteAmount,
        uint256 ethAmount,
        uint256 minBPT
    );

    event LogMintSNoteFromWETH(
        address indexed account,
        uint256 noteAmount,
        uint256 wethAmount,
        uint256 minBPT
    );

    event LogStartCoolDown(address indexed account);

    event LogStopCoolDown(address indexed account);

    event LogRedeemSNote(
        address indexed account,
        uint256 sNOTEAmount,
        uint256 minWETH,
        uint256 minNOTE,
        bool redeemWETH
    );
}
