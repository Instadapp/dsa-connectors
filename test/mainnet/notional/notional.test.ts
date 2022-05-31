import { expect } from "chai";
import hre from "hardhat";
const { waffle, ethers } = hre;
const { provider, deployContract } = waffle

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2"
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner"
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";
import contracts from "./notional.contracts";
import helpers from "./notional.helpers";

import { ConnectV2Notional__factory } from "../../../typechain";
import { BigNumber } from "ethers";

const DAI_WHALE = "0x6dfaf865a93d3b0b5cfd1b4db192d1505676645b";
const CDAI_WHALE = "0x33b890d6574172e93e58528cd99123a88c0756e9";
const ETH_WHALE = "0x7D24796f7dDB17d73e8B1d0A3bbD103FBA2cb2FE";
const CETH_WHALE = "0x1a1cd9c606727a7400bb2da6e4d5c70db5b4cade";
const WETH_WHALE = "0x6555e1cc97d3cba6eaddebbcd7ca51d75771e0b8";
const BPT_WHALE = "0x38de42f4ba8a35056b33a746a6b45be9b1c3b9d2";
const MaxUint96 = BigNumber.from("0xffffffffffffffffffffffff");
const DEPOSIT_ASSET = 1;
const DEPOSIT_UNDERLYING = 2;
const DEPOSIT_ASSET_MINT_NTOKEN = 3;
const DEPOSIT_UNDERLYING_MINT_NTOKEN = 4;
const ETH_ID = 1;
const DAI_ID = 2;
const MARKET_3M = 1;

describe("Notional", function () {
    const connectorName = "NOTIONAL-TEST-A"

    let dsaWallet0: any;
    let masterSigner: any;
    let instaConnectorsV2: any;
    let connector: any;
    let notional: any;
    let snote: any;
    let daiToken: any;
    let cdaiToken: any;
    let cethToken: any;
    let wethToken: any;
    let bptToken: any;
    let noteToken: any;
    let daiWhale: any;
    let cdaiWhale: any;
    let cethWhale: any;
    let wethWhale: any;
    let bptWhale: any;

    const wallets = provider.getWallets()
    const [wallet0, wallet1, wallet2, wallet3] = wallets
    beforeEach(async () => {
        await hre.network.provider.request({
            method: "hardhat_reset",
            params: [
                {
                    forking: {
                        //@ts-ignore
                        jsonRpcUrl: hre.config.networks.hardhat.forking.url,
                        blockNumber: 14483893,
                    },
                },
            ],
        });
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [DAI_WHALE]
        })
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [CDAI_WHALE]
        })
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [ETH_WHALE]
        })
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [CETH_WHALE]
        })
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [WETH_WHALE]
        })
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [BPT_WHALE]
        })

        masterSigner = await getMasterSigner()
        instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
        connector = await deployAndEnableConnector({
            connectorName,
            contractArtifact: ConnectV2Notional__factory,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })
        notional = new ethers.Contract(
            contracts.NOTIONAL_CONTRACT_ADDRESS,
            contracts.NOTIONAL_CONTRACT_ABI,
            ethers.provider
        );
        snote = new ethers.Contract(
            contracts.SNOTE_CONTRACT_ADDRESS,
            contracts.ERC20_TOKEN_ABI,
            ethers.provider
        )
        daiToken = new ethers.Contract(
            contracts.DAI_TOKEN_ADDRESS,
            contracts.ERC20_TOKEN_ABI,
            ethers.provider
        );
        daiWhale = await ethers.getSigner(DAI_WHALE);
        cdaiToken = new ethers.Contract(
            contracts.CDAI_TOKEN_ADDRESS,
            contracts.ERC20_TOKEN_ABI,
            ethers.provider
        );
        cdaiWhale = await ethers.getSigner(CDAI_WHALE);
        cethToken = new ethers.Contract(
            contracts.CETH_TOKEN_ADDRESS,
            contracts.ERC20_TOKEN_ABI,
            ethers.provider
        );
        cethWhale = await ethers.getSigner(CETH_WHALE);
        wethToken = new ethers.Contract(
            contracts.WETH_TOKEN_ADDRESS,
            contracts.ERC20_TOKEN_ABI,
            ethers.provider
        );
        wethWhale = await ethers.getSigner(WETH_WHALE);
        bptToken = new ethers.Contract(
            contracts.BPT_TOKEN_ADDRESS,
            contracts.ERC20_TOKEN_ABI,
            ethers.provider
        );
        bptWhale = await ethers.getSigner(BPT_WHALE);
        noteToken = new ethers.Contract(
            contracts.NOTE_TOKEN_ADDRESS,
            contracts.ERC20_TOKEN_ABI,
            ethers.provider
        )
        dsaWallet0 = await buildDSAv2(wallet0.address);
    });

    describe("Deposit Tests", function () {
        it("test_deposit_ETH_underlying", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            const depositAmount = ethers.utils.parseEther("1");
            await helpers.depositCollteral(dsaWallet0, wallet0, wallet1, ETH_ID, depositAmount, true);
            const bal = await notional.callStatic.getAccountBalance(ETH_ID, dsaWallet0.address);
            // balance in internal asset precision
            expect(bal[0], "expect at least 49 cETH").to.be.gte(ethers.utils.parseUnits("4900000000", 0));
            expect(bal[1], "expect 0 nETH").to.be.equal(ethers.utils.parseUnits("0", 0));
        });

        it("test_deposit_ETH_asset", async function () {
            const depositAmount = ethers.utils.parseUnits("1", 8);
            await cethToken.connect(cethWhale).transfer(dsaWallet0.address, depositAmount);
            await helpers.depositCollteral(dsaWallet0, wallet0, wallet1, ETH_ID, depositAmount, false);
            const bal = await notional.callStatic.getAccountBalance(ETH_ID, dsaWallet0.address);
            // balance in internal asset precision
            expect(bal[0], "expect at least 1 cETH").to.be.gte(ethers.utils.parseUnits("100000000", 0));
            expect(bal[1], "expect 0 nETH").to.be.equal(ethers.utils.parseUnits("0", 0));
        });

        it("test_deposit_DAI_underlying", async function () {
            const depositAmount = ethers.utils.parseUnits("1000", 18);
            await daiToken.connect(daiWhale).transfer(dsaWallet0.address, depositAmount);
            await helpers.depositCollteral(dsaWallet0, wallet0, wallet1, DAI_ID, depositAmount, true);
            const bal = await notional.callStatic.getAccountBalance(DAI_ID, dsaWallet0.address);
            // balance in internal asset precision
            expect(bal[0], "expect at least 45000 cDAI").to.be.gte(ethers.utils.parseUnits("4500000000000", 0));
            expect(bal[1], "expect 0 nDAI").to.be.equal(ethers.utils.parseUnits("0", 0));
        });

        it("test_deposit_DAI_asset", async function () {
            const depositAmount = ethers.utils.parseUnits("1000", 8);
            await cdaiToken.connect(cdaiWhale).transfer(dsaWallet0.address, depositAmount);
            await helpers.depositCollteral(dsaWallet0, wallet0, wallet1, DAI_ID, depositAmount, false);
            const bal = await notional.callStatic.getAccountBalance(DAI_ID, dsaWallet0.address);
            // balance in internal asset precision
            expect(bal[0], "expect at least 1000 cDAI").to.be.gte(ethers.utils.parseUnits("100000000000", 0));
            expect(bal[1], "expect 0 nDAI").to.be.equal(ethers.utils.parseUnits("0", 0));
        });

        it("test_deposit_ETH_underlying_and_mint_ntoken", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            const depositAmount = ethers.utils.parseEther("1");
            await helpers.depositAndMintNToken(dsaWallet0, wallet0, wallet1, ETH_ID, depositAmount, true);
            const bal = await notional.callStatic.getAccountBalance(ETH_ID, dsaWallet0.address);
            expect(bal[0], "expect 0 balance").to.be.equal(ethers.utils.parseUnits("0", 0));
            expect(bal[1], "expect at least 49 nETH").to.be.gte(ethers.utils.parseUnits("4900000000", 0));
        });
    });

    describe("Lend Tests", function () {
        it("test_deposit_ETH_underlying_and_lend", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            const depositAmount = ethers.utils.parseEther("10");
            const fcash = ethers.utils.parseUnits("9", 8);
            await helpers.depositAndLend(dsaWallet0, wallet0, wallet1, ETH_ID, true, depositAmount, MARKET_3M, fcash);
            const portfolio = await notional.getAccountPortfolio(dsaWallet0.address);
            expect(portfolio.length, "expect 1 lending position").to.be.equal(1);
            expect(portfolio[0][3], "expect 9 fETH").to.be.gte(ethers.utils.parseUnits("900000000", 0));
        });

        it("test_deposit_ETH_asset_and_lend", async function () {
            const depositAmount = ethers.utils.parseUnits("1", 8);
            await cethToken.connect(cethWhale).transfer(dsaWallet0.address, depositAmount);
            const fcash = ethers.utils.parseUnits("0.01", 8);
            await helpers.depositAndLend(dsaWallet0, wallet0, wallet1, ETH_ID, false, depositAmount, MARKET_3M, fcash);
            const portfolio = await notional.getAccountPortfolio(dsaWallet0.address);
            expect(portfolio.length, "expect 1 lending position").to.be.equal(1);
            expect(portfolio[0][3], "expect 0.01 fETH").to.be.gte(ethers.utils.parseUnits("1000000", 0));
        });

        it("test_deposit_DAI_underlying_and_lend", async function () {
            const depositAmount = ethers.utils.parseUnits("1000", 18);
            await daiToken.connect(daiWhale).transfer(dsaWallet0.address, depositAmount);
            const fcash = ethers.utils.parseUnits("100", 8);
            await helpers.depositAndLend(dsaWallet0, wallet0, wallet1, DAI_ID, true, depositAmount, MARKET_3M, fcash);
            const portfolio = await notional.getAccountPortfolio(dsaWallet0.address);
            expect(portfolio.length, "expect 1 lending position").to.be.equal(1);
            expect(portfolio[0][3], "expect 100 fDAI").to.be.gte(ethers.utils.parseUnits("10000000000", 0));
        });

        it("test_deposit_DAI_asset_and_lend", async function () {
            const depositAmount = ethers.utils.parseUnits("1000", 8);
            await cdaiToken.connect(cdaiWhale).transfer(dsaWallet0.address, depositAmount);
            const fcash = ethers.utils.parseUnits("10", 8);
            await helpers.depositAndLend(dsaWallet0, wallet0, wallet1, DAI_ID, false, depositAmount, MARKET_3M, fcash);
            const portfolio = await notional.getAccountPortfolio(dsaWallet0.address);
            expect(portfolio.length, "expect 1 lending position").to.be.equal(1);
            expect(portfolio[0][3], "expect 10 fDAI").to.be.gte(ethers.utils.parseUnits("1000000000", 0));
        });

        it("test_withdraw_lend_ETH", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            const depositAmount = ethers.utils.parseEther("10");
            const fcash = ethers.utils.parseUnits("9", 8);
            await helpers.depositAndLend(dsaWallet0, wallet0, wallet1, ETH_ID, true, depositAmount, MARKET_3M, fcash);
            const before = await notional.getAccountPortfolio(dsaWallet0.address);
            expect(before.length, "expect 1 lending position").to.be.equal(1);
            expect(before[0][3], "expect 9 fETH").to.be.gte(ethers.utils.parseUnits("900000000", 0));
            await helpers.withdrawLend(dsaWallet0, wallet0, wallet1, ETH_ID, MARKET_3M, fcash);
            const after = await notional.getAccountPortfolio(dsaWallet0.address);
            expect(after.length, "expect lending position to be closed out").to.be.equal(0);
        });
    });

    describe("Borrow Tests", function () {
        it("test_deposit_ETH_and_borrow_DAI_underlying", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            const depositAmount = ethers.utils.parseEther("10");
            const fcash = ethers.utils.parseUnits("1000", 8);
            await helpers.depositCollateralBorrowAndWithdraw(
                dsaWallet0, wallet0, wallet1, ETH_ID, DEPOSIT_UNDERLYING, depositAmount, DAI_ID, MARKET_3M, fcash, true
            );
            expect(
                await daiToken.balanceOf(dsaWallet0.address),
                "expect DSA wallet to contain borrowed balance minus fees"
            ).to.be.gte(ethers.utils.parseEther("985"));
        });

        it("test_deposit_ETH_and_borrow_DAI_asset", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            const depositAmount = ethers.utils.parseEther("10");
            const fcash = ethers.utils.parseUnits("1000", 8);
            await helpers.depositCollateralBorrowAndWithdraw(
                dsaWallet0, wallet0, wallet1, ETH_ID, DEPOSIT_UNDERLYING, depositAmount, DAI_ID, MARKET_3M, fcash, false
            );
            expect(
                await cdaiToken.balanceOf(dsaWallet0.address),
                "expect DSA wallet to contain borrowed balance minus fees"
            ).to.be.gte(ethers.utils.parseUnits("4490000000000", 0));
        });

        it("test_deposit_DAI_underlying_and_borrow_ETH", async function () {
            const depositAmount = ethers.utils.parseUnits("20000", 18);
            await daiToken.connect(daiWhale).transfer(dsaWallet0.address, depositAmount);
            const fcash = ethers.utils.parseUnits("1", 8);
            await helpers.depositCollateralBorrowAndWithdraw(
                dsaWallet0, wallet0, wallet1, DAI_ID, DEPOSIT_UNDERLYING, depositAmount, ETH_ID, MARKET_3M, fcash, true
            );
            expect(
                await ethers.provider.getBalance(dsaWallet0.address),
                "expect DSA wallet to contain borrowed balance minus fees"
            ).to.be.gte(ethers.utils.parseEther("0.99"));
        });

        it("test_deposit_DAI_asset_and_borrow_ETH", async function () {
            const depositAmount = ethers.utils.parseUnits("1000000", 8);
            await cdaiToken.connect(cdaiWhale).transfer(dsaWallet0.address, depositAmount);
            const fcash = ethers.utils.parseUnits("1", 8);
            await helpers.depositCollateralBorrowAndWithdraw(
                dsaWallet0, wallet0, wallet1, DAI_ID, DEPOSIT_ASSET, depositAmount, ETH_ID, MARKET_3M, fcash, true
            );
            expect(
                await ethers.provider.getBalance(dsaWallet0.address),
                "expect DSA wallet to contain borrowed balance minus fees"
            ).to.be.gte(ethers.utils.parseEther("0.99"));
        });

        it("test_mint_nDAI_underlying_and_borrow_ETH", async function () {
            const depositAmount = ethers.utils.parseUnits("20000", 18);
            await daiToken.connect(daiWhale).transfer(dsaWallet0.address, depositAmount);
            const fcash = ethers.utils.parseUnits("1", 8);
            await helpers.depositCollateralBorrowAndWithdraw(
                dsaWallet0, wallet0, wallet1, DAI_ID, DEPOSIT_UNDERLYING_MINT_NTOKEN, depositAmount, ETH_ID, MARKET_3M, fcash, true
            );
            expect(
                await ethers.provider.getBalance(dsaWallet0.address),
                "expect DSA wallet to contain borrowed balance minus fees"
            ).to.be.gte(ethers.utils.parseEther("0.99"));
        });

        it("test_mint_nDAI_asset_and_borrow_ETH", async function () {
            const depositAmount = ethers.utils.parseUnits("1000000", 8);
            await cdaiToken.connect(cdaiWhale).transfer(dsaWallet0.address, depositAmount);
            const fcash = ethers.utils.parseUnits("1", 8);
            await helpers.depositCollateralBorrowAndWithdraw(
                dsaWallet0, wallet0, wallet1, DAI_ID, DEPOSIT_ASSET_MINT_NTOKEN, depositAmount, ETH_ID, MARKET_3M, fcash, true
            );
            expect(
                await ethers.provider.getBalance(dsaWallet0.address),
                "expect DSA wallet to contain borrowed balance minus fees"
            ).to.be.gte(ethers.utils.parseEther("0.99"));
        });
    });

    describe("Withdraw Tests", function () {
        it("test_withdraw_ETH_underlying", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            const depositAmount = ethers.utils.parseEther("1");
            await helpers.depositCollteral(dsaWallet0, wallet0, wallet1, 1, depositAmount, true);
            await helpers.withdrawCollateral(dsaWallet0, wallet0, wallet1, 1, ethers.constants.MaxUint256, true);
            expect(
                await ethers.provider.getBalance(dsaWallet0.address),
                "expect DSA wallet to contain underlying funds"
            ).to.be.gte(ethers.utils.parseEther("10"));
        });

        it("test_withdraw_ETH_asset", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            const depositAmount = ethers.utils.parseEther("1");
            await helpers.depositCollteral(dsaWallet0, wallet0, wallet1, ETH_ID, depositAmount, true);
            await helpers.withdrawCollateral(dsaWallet0, wallet0, wallet1, ETH_ID, ethers.constants.MaxUint256, false);
            expect(
                await cethToken.balanceOf(dsaWallet0.address),
                "expect DSA wallet to contain cToken funds"
            ).to.be.gte(ethers.utils.parseUnits("4900000000", 0));
        });

        it("test_redeem_DAI_raw", async function () {
            const depositAmount = ethers.utils.parseUnits("1000", 8);
            await cdaiToken.connect(cdaiWhale).transfer(dsaWallet0.address, depositAmount);
            await helpers.depositAndMintNToken(dsaWallet0, wallet0, wallet1, DAI_ID, depositAmount, false);
            await helpers.redeemNTokenRaw(dsaWallet0, wallet0, wallet1, DAI_ID, true, MaxUint96)
            const bal = await notional.callStatic.getAccountBalance(DAI_ID, dsaWallet0.address);
            expect(bal[0], "expect cDAI balance after redemption").to.be.gte(ethers.utils.parseUnits("99000000000", 0));
            expect(bal[1], "expect 0 nDAI").to.be.equal(ethers.utils.parseEther("0"));
        });

        it("test_redeem_DAI_and_withdraw_redeem", async function () {
            const depositAmount = ethers.utils.parseUnits("1000", 8);
            await cdaiToken.connect(cdaiWhale).transfer(dsaWallet0.address, depositAmount);
            await helpers.depositAndMintNToken(dsaWallet0, wallet0, wallet1, DAI_ID, depositAmount, false);
            await helpers.redeemNTokenAndWithdraw(dsaWallet0, wallet0, wallet1, DAI_ID, MaxUint96, ethers.constants.MaxUint256, true);
            const bal = await notional.callStatic.getAccountBalance(DAI_ID, dsaWallet0.address);
            expect(bal[0], "expect 0 cDAI balance").to.be.equal(ethers.utils.parseEther("0"));
            expect(bal[1], "expect 0 nDAI balance").to.be.equal(ethers.utils.parseEther("0"));
        });

        it("test_redeem_DAI_and_withdraw_no_redeem", async function () {
            const depositAmount = ethers.utils.parseUnits("1000", 8);
            await cdaiToken.connect(cdaiWhale).transfer(dsaWallet0.address, depositAmount);
            await helpers.depositAndMintNToken(dsaWallet0, wallet0, wallet1, DAI_ID, depositAmount, false);
            expect(await cdaiToken.balanceOf(dsaWallet0.address)).to.be.equal(ethers.utils.parseEther("0"));
            await helpers.redeemNTokenAndWithdraw(dsaWallet0, wallet0, wallet1, DAI_ID, MaxUint96, ethers.constants.MaxUint256, false);
            const bal = await notional.callStatic.getAccountBalance(DAI_ID, dsaWallet0.address);
            expect(bal[0], "expect 0 cDAI balance").to.be.equal(ethers.utils.parseEther("0"));
            expect(bal[1], "expect 0 nDAI balance").to.be.equal(ethers.utils.parseEther("0"));
            expect(
                await cdaiToken.balanceOf(dsaWallet0.address),
                "expect DSA wallet to contain cToken funds"
            ).to.be.gte(ethers.utils.parseUnits("99000000000", 0));
        });

        it("test_redeem_DAI_and_deleverage", async function () {
            const depositAmount = ethers.utils.parseUnits("20000", 18);
            await daiToken.connect(daiWhale).transfer(dsaWallet0.address, depositAmount);
            const fcash = ethers.utils.parseUnits("1", 8);
            await helpers.depositCollateralBorrowAndWithdraw(
                dsaWallet0, wallet0, wallet1, DAI_ID, DEPOSIT_UNDERLYING, depositAmount, ETH_ID, MARKET_3M, fcash, true
            );
            const bal = await ethers.provider.getBalance(dsaWallet0.address);
            await helpers.depositAndMintNToken(dsaWallet0, wallet0, wallet1, ETH_ID, bal, true);
            const before = await notional.getAccountPortfolio(dsaWallet0.address);
            expect(before.length, "expect 1 fDAI debt position").to.be.equal(1);
            expect(before[0][3], "expect fDAI debt position to equal borrow amount").to.be.lte(ethers.utils.parseUnits("-100000000", 0));
            const fcash2 = ethers.utils.parseUnits("0.98", 8);
            await helpers.redeemNTokenAndDeleverage(dsaWallet0, wallet0, wallet1, ETH_ID, MaxUint96, MARKET_3M, fcash2);
            const after = await notional.getAccountPortfolio(dsaWallet0.address);
            expect(after.length, "expect 1 fDAI debt position after deleverage").to.be.equal(1);
            expect(after[0][3], "expect fDAI debt balance to go down after deleverage").to.be.lte(ethers.utils.parseUnits("-2000000", 0));
        });
    });

    describe("Staking Tests", function () {
        it("test_stake_ETH", async function () {
            const depositAmount = ethers.utils.parseEther("1");
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: depositAmount
            });
            expect(await snote.balanceOf(dsaWallet0.address), "expect 0 initial sNOTE balance").to.be.equal(0);
            await helpers.mintSNoteFromETH(dsaWallet0, wallet0, wallet1, BigNumber.from(0), depositAmount, BigNumber.from(0));
            expect(await snote.balanceOf(dsaWallet0.address), "expect sNOTE balance to increase").to.be.gte(ethers.utils.parseEther("297"))
        });

        it("test_stake_WETH", async function () {
            const depositAmount = ethers.utils.parseEther("1");
            await wethToken.connect(wethWhale).transfer(dsaWallet0.address, depositAmount);
            expect(await snote.balanceOf(dsaWallet0.address), "expect 0 initial sNOTE balance").to.be.equal(0);
            await helpers.mintSNoteFromWETH(dsaWallet0, wallet0, wallet1, BigNumber.from(0), depositAmount, BigNumber.from(0));
            expect(await snote.balanceOf(dsaWallet0.address), "expect sNOTE balance to increase").to.be.gte(ethers.utils.parseEther("297"))
        });

        it("test_stake_BPT", async function () {
            const depositAmount = ethers.utils.parseEther("1");
            await wallet0.sendTransaction({
                to: bptWhale.address,
                value: depositAmount
            });
            await bptToken.connect(bptWhale).transfer(dsaWallet0.address, depositAmount);
            expect(await snote.balanceOf(dsaWallet0.address), "expect 0 initial sNOTE balance").to.be.equal(0);
            await helpers.mintSNoteFromBPT(dsaWallet0, wallet0, wallet1, depositAmount);
            expect(await snote.balanceOf(dsaWallet0.address), "expect sNOTE balance to increase").to.be.eq(depositAmount)
        });

        it("test_unstake_success", async function () {
            const depositAmount = ethers.utils.parseEther("1");
            await wallet0.sendTransaction({
                to: bptWhale.address,
                value: depositAmount
            });
            await bptToken.connect(bptWhale).transfer(dsaWallet0.address, depositAmount);
            await helpers.mintSNoteFromBPT(dsaWallet0, wallet0, wallet1, depositAmount);
            await helpers.startCoolDown(dsaWallet0, wallet0, wallet1);
            // Skip ahead 16 days
            await hre.network.provider.send("evm_increaseTime", [1382400])
            await hre.network.provider.send("evm_mine")
            await helpers.redeemSNote(
                dsaWallet0, 
                wallet0, 
                wallet1, 
                ethers.constants.MaxUint256, 
                BigNumber.from(0), 
                BigNumber.from(0), 
                true
            );
            expect(await noteToken.balanceOf(dsaWallet0.address)).to.be.gte(ethers.utils.parseUnits("50000000000", 0));
            expect(await provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseUnits("32500000000000000", 0))
        });

        it("test_unstable_failure", async function () {
            const depositAmount = ethers.utils.parseEther("1");
            await wallet0.sendTransaction({
                to: bptWhale.address,
                value: depositAmount
            });
            await bptToken.connect(bptWhale).transfer(dsaWallet0.address, depositAmount);
            await helpers.mintSNoteFromBPT(dsaWallet0, wallet0, wallet1, depositAmount);
            await expect(helpers.redeemSNote(
                dsaWallet0, 
                wallet0, 
                wallet1, 
                ethers.constants.MaxUint256, 
                BigNumber.from(0), 
                BigNumber.from(0), 
                true
            )).to.be.revertedWith("Not in Redemption Window");
        });
    });
});
