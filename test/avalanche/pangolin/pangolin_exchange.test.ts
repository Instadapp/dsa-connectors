import { expect } from "chai";
import hre from "hardhat";

const { waffle, ethers } = hre;
const { provider } = waffle;

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/avalanche/addresses";
import { abis } from "../../../scripts/constant/abis";
import { Signer, Contract } from "ethers";

import { ConnectV2PngAvalanche__factory } from "../../../typechain";

const PNG_ADDRESS  = "0x60781C2586D68229fde47564546784ab3fACA982";
const WAVAX_ADDRESS = "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7";
const PNG_AVAX_LP_ADDRESS = "0xd7538cABBf8605BdE1f4901B47B8D42c61DE0367";

describe("Pangolin DEX - Avalanche", function () {
    const pangolinConnectorName = "PANGOLIN-TEST-A"
    
    let dsaWallet0: Contract;
    let masterSigner: Signer;
    let instaConnectorsV2: Contract;
    let pangolinConnector: Contract;
    
    const wallets = provider.getWallets()
    const [wallet0, wallet1] = wallets
    before(async () => {
        await hre.network.provider.request({
            method: "hardhat_reset",
            params: [
                {
                    forking: {
                        jsonRpcUrl: `https://api.avax.network/ext/bc/C/rpc`,
                        blockNumber: 8197390
                    },
                },
            ],
        });

        masterSigner = await getMasterSigner();
        instaConnectorsV2 = await ethers.getContractAt(
            abis.core.connectorsV2,
            addresses.core.connectorsV2
        );

        // Deploy and enable Pangolin Connector
        pangolinConnector = await deployAndEnableConnector({
            connectorName: pangolinConnectorName,
            contractArtifact: ConnectV2PngAvalanche__factory,
            signer: masterSigner,
            connectors: instaConnectorsV2
        });
        console.log("Pangolin Connector address: "+ pangolinConnector.address);
    })

    it("Should have contracts deployed.", async function () {
        expect(!!instaConnectorsV2.address).to.be.true;
        expect(!!pangolinConnector.address).to.be.true;
        expect(!!(await masterSigner.getAddress())).to.be.true;
      });
    
    describe("DSA wallet setup", function () {
        it("Should build DSA v2", async function () {
            dsaWallet0 = await buildDSAv2(wallet0.getAddress())
            expect(!!dsaWallet0.address).to.be.true;
        });

        it("Deposit 10 AVAX into DSA wallet", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
        });
    });

    describe("Main - PANGOLIN PNG/AVAX Liquidity Test", function () {

        it("Should use pangolin to swap AVAX for PNG, and deposit to PNG/AVAX LP", async function () {
            const amount = ethers.utils.parseEther("100"); // 100 PNG
            const int_slippage = 0.03
            const slippage = ethers.utils.parseEther(int_slippage.toString());
            const setId = "83528353";
    
            const PangolinRouterABI = [
                "function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts)"
            ];
    
            // Get amount of AVAX for 100 POOL from Pangolin
            const PangolinRouter = await ethers.getContractAt(
                PangolinRouterABI, 
                "0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106"
            );
            const amounts = await PangolinRouter.getAmountsOut(
                amount, 
                [
                    PNG_ADDRESS, 
                    WAVAX_ADDRESS
                ]
            );

            const amtA = amounts[0];
            const amtB = amounts[1];
            const unitAmt = (amtB * (1 + int_slippage)) / amtA;
            const unitAmount = ethers.utils.parseEther(unitAmt.toString());

            const spells = [
                {
                    connector: pangolinConnectorName,
                    method: "buy",
                    args: [
                        PNG_ADDRESS, 
                        "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", 
                        amount, 
                        unitAmount, 
                        0, 
                        setId
                    ]
                },
                {
                    connector: pangolinConnectorName,
                    method: "deposit",
                    args: [
                        PNG_ADDRESS, 
                        "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", 
                        amount, 
                        unitAmount, 
                        slippage, 
                        0, 
                        setId
                    ]
                },
            ];
    
            // Before Spell
            let avaxBalance = await ethers.provider.getBalance(dsaWallet0.address);
            expect(avaxBalance, `AVAX Balance equals 10`).to.be.eq(ethers.utils.parseEther("10"));
    
            let pngToken = await ethers.getContractAt(abis.basic.erc20, PNG_ADDRESS);
            const pngBalance = await pngToken.balanceOf(dsaWallet0.address);
            expect(pngBalance, `PNG Token greater than 0`).to.be.eq(0);
    
            let pangolinLPToken = await ethers.getContractAt(
                abis.basic.erc20, 
                PNG_AVAX_LP_ADDRESS
            );
            const pangolinPoolAVAXBalance = await pangolinLPToken.balanceOf(dsaWallet0.address);
            expect(pangolinPoolAVAXBalance, `Pangolin PNG/AVAX LP equals 0`).to.be.eq(0);
    
            // Run spell transaction
            const tx = await dsaWallet0.connect(wallet0).cast(
                ...encodeSpells(spells), wallet1.address
            );
            const receipt = await tx.wait();
    
            // After spell
            avaxBalance = await ethers.provider.getBalance(dsaWallet0.address);
            expect(avaxBalance, `AVAX Balance less than 10`).to.be.lt(ethers.utils.parseEther("10"));
    
            const pngBalanceAfter = await pngToken.balanceOf(dsaWallet0.address)
            expect(pngBalanceAfter, `PNG Token to be same after spell`).to.be.eq(pngBalance);
    
            const pangolinPoolAVAXBalanceAfter = await pangolinLPToken.balanceOf(dsaWallet0.address);
            expect(
                pangolinPoolAVAXBalanceAfter, 
                `Pangolin PNG/AVAX LP greater than 0`
            ).to.be.gt(0);
        });

        it("Should use pangolin to withdraw to PNG/AVAX LP, and swap PNG for AVAX", async function () {
            const amount = ethers.utils.parseEther("100"); // 100 PNG
            const int_slippage = 0.03
    
            // Before Spell
            let avaxBalance = await ethers.provider.getBalance(dsaWallet0.address);
            let pngToken = await ethers.getContractAt(abis.basic.erc20, PNG_ADDRESS);
            let pangolinLPToken = await ethers.getContractAt(
                abis.basic.erc20, 
                PNG_AVAX_LP_ADDRESS
            );

            const pngBalance = await pngToken.balanceOf(dsaWallet0.address)
            expect(pngBalance, `PNG Token balance equal to 0`).to.be.eq(0);
    
            const pangolinPoolAVAXBalance = await pangolinLPToken.balanceOf(dsaWallet0.address);
            expect(pangolinPoolAVAXBalance, `Pangolin PNG/AVAX LP greater than 0`).to.be.gt(0);
    
            const PangolinRouterABI = [
                "function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts)"
            ];
    
            // Get amount of avax for 100 PNG from Pangolin
            const PangolinRouter= await ethers.getContractAt(
                PangolinRouterABI, 
                "0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106"
            );
            const amounts = await PangolinRouter.getAmountsOut(
                amount, 
                [
                    PNG_ADDRESS,
                    WAVAX_ADDRESS
                ]
            );
            const amtA = amounts[0];
            const amtB = amounts[1];
            const unitAmtA = ethers.utils.parseEther(
                (amtA * (1 - int_slippage) / pangolinPoolAVAXBalance).toString()
            );
            const unitAmtB = ethers.utils.parseEther(
                (amtB * (1 - int_slippage) / pangolinPoolAVAXBalance).toString()
            );

            let spells = [
                {
                    connector: pangolinConnectorName,
                    method: "withdraw",
                    args: [
                        PNG_ADDRESS, 
                        "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", 
                        pangolinPoolAVAXBalance, 
                        unitAmtA, 
                        unitAmtB, 
                        0, 
                        [
                            0,
                            0
                        ]
                    ]
                },
            ];

            // Run spell transaction (withdraw token of pool)
            const tx = await dsaWallet0.connect(wallet0).cast(
                ...encodeSpells(spells), 
                wallet1.address
            );
            const receipt = await tx.wait();
    
            // After spell
            const pangolinPoolAVAXBalanceAfter = await pangolinLPToken.balanceOf(
                dsaWallet0.address
            );
            expect(pangolinPoolAVAXBalanceAfter, `Pangolin PNG/AVAX LP equal 0`).to.be.eq(0);

            let pngBalanceAfter = await pngToken.balanceOf(dsaWallet0.address);
            expect(pngBalanceAfter, `PNG Token balance greater than`).to.be.gt(0);
            const unitAmt = amount.div(pngBalanceAfter);

            spells = [
                {
                    connector: pangolinConnectorName,
                    method: "sell",
                    args: [
                        "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", 
                        PNG_ADDRESS, 
                        pngBalanceAfter, 
                        unitAmt, 
                        0, 
                        0
                    ]
                },
            ];

            // Run spell transaction (withdraw token of pool)
            const tx2 = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
            const receipt2 = await tx2.wait();
    
            let avaxBalanceAfter = await ethers.provider.getBalance(dsaWallet0.address);
            expect(
                avaxBalanceAfter, 
                `AVAX Balance After greater than AVAX Balance Before`
            ).to.be.gt(avaxBalance);
    
            pngBalanceAfter = await pngToken.balanceOf(dsaWallet0.address);
            expect(pngBalanceAfter, `PNG Token balance equal 0`).to.be.eq(0);
        });
      })
});
