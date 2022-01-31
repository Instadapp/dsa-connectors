const encodeSpells = require("../../scripts/encodeSpells.js")

const depositCollteral = async (dsa, authority, referrer, currencyId, amount, underlying) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "depositCollateral",
            args: [currencyId, underlying, amount, 0, 0]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
};

const depositAndMintNToken = async (dsa, authority, referrer, currencyId, amount, underlying) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "depositAndMintNToken",
            args: [currencyId, amount, underlying, 0, 0]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
}

const depositAndLend = async (dsa, authority, referrer, currencyId, underlying, amount, market, fcash, minRate) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "depositAndLend",
            args: [currencyId, amount, underlying, market, fcash, minRate, 0]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()    
};

const withdrawCollateral = async (dsa, authority, referrer, currencyId, amount, underlying) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "withdrawCollateral",
            args: [currencyId, underlying, amount, 0, 0]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
};

const redeemNTokenRaw = async (dsa, authority, referrer, currencyId, sellTokenAssets, tokensToRedeem) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "redeemNTokenRaw",
            args: [currencyId, sellTokenAssets, tokensToRedeem, 0, 0]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
};

const redeemNTokenAndWithdraw = async (dsa, authority, referrer, currencyId, tokensToRedeem, amountToWithdraw, redeemToUnderlying) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "redeemNTokenAndWithdraw",
            args: [currencyId, tokensToRedeem, amountToWithdraw, redeemToUnderlying, 0, 0]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
};

const redeemNTokenAndDeleverage = async (dsa, authority, referrer, currencyId, tokensToRedeem, marketIndex, fCashAmount, minLendRate) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "redeemNTokenAndDeleverage",
            args: [currencyId, tokensToRedeem, marketIndex, fCashAmount, minLendRate, 0]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
};

const depositCollateralBorrowAndWithdraw = async (
    dsa,
    authority,
    referrer,
    depositCurrencyId,
    depositUnderlying,
    depositAmount,
    borrowCurrencyId,
    marketIndex,
    fCashAmount,
    maxBorrowRate,
    redeedmUnderlying
) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "depositCollateralBorrowAndWithdraw",
            args: [
                depositCurrencyId,
                depositUnderlying,
                depositAmount,
                borrowCurrencyId,
                marketIndex,
                fCashAmount,
                maxBorrowRate,
                redeedmUnderlying,
                0,
                0
            ]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
};

const withdrawLend = async (dsa, authority, referrer, currencyId, marketIndex, fCashAmount, maxBorrowRate) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "withdrawLend",
            args: [currencyId, marketIndex, fCashAmount, maxBorrowRate, 0]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
};

const depositERC20 = async (dsa, authority, referrer, token, amount) => {
    const spells = [
        {
            connector: "BASIC-A",
            method: "deposit",
            args: [token, amount, 0, 0]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
};

module.exports = {
    depositCollteral,
    depositAndMintNToken,
    depositAndLend,
    withdrawCollateral,
    withdrawLend,
    redeemNTokenRaw,
    redeemNTokenAndWithdraw,
    redeemNTokenAndDeleverage,
    depositCollateralBorrowAndWithdraw,
    depositERC20
};
