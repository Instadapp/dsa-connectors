import { BigNumber } from "ethers";
import { encodeSpells } from "../../../scripts/tests/encodeSpells"

const depositCollteral = async (
    dsa: any,
    authority: any,
    referrer: any,
    currencyId: number,
    amount: BigNumber,
    underlying: boolean
) => {
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

const depositAndMintNToken = async (
    dsa: any,
    authority: any,
    referrer: any,
    currencyId: number,
    amount: BigNumber,
    underlying: boolean
) => {
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

const depositAndLend = async (
    dsa: any,
    authority: any,
    referrer: any,
    currencyId: number,
    underlying: boolean,
    amount: BigNumber,
    market: number,
    fcash: BigNumber
) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "depositAndLend",
            args: [currencyId, amount, underlying, market, fcash, 0, 0]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
};

const withdrawCollateral = async (
    dsa: any,
    authority: any,
    referrer: any,
    currencyId: number,
    amount: BigNumber,
    underlying: boolean
) => {
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

const redeemNTokenRaw = async (
    dsa: any,
    authority: any,
    referrer: any,
    currencyId: number,
    sellTokenAssets: boolean,
    tokensToRedeem: BigNumber
) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "redeemNTokenRaw",
            args: [currencyId, sellTokenAssets, tokensToRedeem, false, 0, 0]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
};

const redeemNTokenAndWithdraw = async (
    dsa: any,
    authority: any,
    referrer: any,
    currencyId: number,
    tokensToRedeem: BigNumber,
    amountToWithdraw: BigNumber,
    redeemToUnderlying: boolean
) => {
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

const redeemNTokenAndDeleverage = async (
    dsa: any,
    authority: any,
    referrer: any,
    currencyId: number,
    tokensToRedeem: BigNumber,
    marketIndex: number,
    fCashAmount: BigNumber
) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "redeemNTokenAndDeleverage",
            args: [currencyId, tokensToRedeem, marketIndex, fCashAmount, 0, 0]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
};

const depositCollateralBorrowAndWithdraw = async (
    dsa: any,
    authority: any,
    referrer: any,
    depositCurrencyId: number,
    depositType: number,
    depositAmount: BigNumber,
    borrowCurrencyId: number,
    marketIndex: number,
    fCashAmount: BigNumber,
    redeedmUnderlying: boolean
) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "depositCollateralBorrowAndWithdraw",
            args: [
                depositCurrencyId,
                depositType,
                depositAmount,
                borrowCurrencyId,
                marketIndex,
                fCashAmount,
                0,
                redeedmUnderlying,
                0,
                0
            ]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
};

const withdrawLend = async (
    dsa: any,
    authority: any,
    referrer: any,
    currencyId: number,
    marketIndex: number,
    fCashAmount: BigNumber
) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "withdrawLend",
            args: [currencyId, marketIndex, fCashAmount, 0, 0]
        }
    ];

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
};

const mintSNoteFromETH = async (
    dsa: any,
    authority: any,
    referrer: any,
    noteAmount: BigNumber, 
    ethAmount: BigNumber,
    minBPT: BigNumber
) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "mintSNoteFromETH",
            args: [noteAmount, ethAmount, minBPT, 0]
        }        
    ]

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
}

const mintSNoteFromWETH = async (
    dsa: any,
    authority: any,
    referrer: any,
    noteAmount: BigNumber,
    wethAmount: BigNumber,
    minBPT: BigNumber
) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "mintSNoteFromWETH",
            args: [noteAmount, wethAmount, minBPT, 0]
        }        
    ]

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
}

const mintSNoteFromBPT = async (
    dsa: any,
    authority: any,
    referrer: any,
    bptAmount: BigNumber
) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "mintSNoteFromBPT",
            args: [bptAmount]
        }        
    ]

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
}

const startCoolDown = async (
    dsa: any,
    authority: any,
    referrer: any
) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "startCoolDown",
            args: []
        }        
    ]

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
}

const stopCoolDown = async (
    dsa: any,
    authority: any,
    referrer: any
) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "stopCoolDown",
            args: []
        }        
    ]

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
}

const redeemSNote = async (
    dsa: any,
    authority: any,
    referrer: any,
    sNOTEAmount: BigNumber,
    minWETH: BigNumber,
    minNOTE: BigNumber,
    redeemWETH: boolean
) => {
    const spells = [
        {
            connector: "NOTIONAL-TEST-A",
            method: "redeemSNote",
            args: [sNOTEAmount, minWETH, minNOTE, redeemWETH]
        }        
    ]

    const tx = await dsa.connect(authority).cast(...encodeSpells(spells), referrer.address);
    await tx.wait()
}

export default {
    depositCollteral,
    depositAndMintNToken,
    depositAndLend,
    withdrawCollateral,
    withdrawLend,
    redeemNTokenRaw,
    redeemNTokenAndWithdraw,
    redeemNTokenAndDeleverage,
    depositCollateralBorrowAndWithdraw,
    mintSNoteFromETH,
    mintSNoteFromWETH,
    mintSNoteFromBPT,
    startCoolDown,
    stopCoolDown,
    redeemSNote
};
