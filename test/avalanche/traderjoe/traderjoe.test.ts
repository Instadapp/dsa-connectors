import { expect } from "chai";
import hre from "hardhat";
const { waffle, ethers } = hre;
const { provider, deployContract} = waffle

import type { Signer, Contract } from "ethers";

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2"
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner"
import { addresses } from "../../../scripts/tests/avalanche/addresses";
import { abis } from "../../../scripts/constant/abis";
import { constants } from "../../../scripts/constant/constant";
import { ConnectV2TraderJoe__factory } from "../../../typechain";

describe("TraderJoe", function () {
    const connectorName = "TRADERJOE-TEST-A"

    let dsaWallet0: any;
    let masterSigner: Signer;
    let instaConnectorsV2: Contract;
    let connector: any;

    const wallets = provider.getWallets()
    const [wallet0, wallet1, wallet2, wallet3] = wallets
    before(async () => {
        // await hre.network.provider.request({
        //     method: "hardhat_reset",
        //     params: [
        //         {
        //             forking: {
        //                 //@ts-ignore
        //                 jsonRpcUrl: hre.config.networks.hardhat.forking.url,
        //                 blockNumber: 11078009,
        //             },
        //         },
        //     ],
        // });
        
        
        masterSigner = await getMasterSigner()
       

        instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
        
        connector = await deployAndEnableConnector({
            connectorName,
            contractArtifact: ConnectV2TraderJoe__factory,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })
        
        console.log("Connector address", connector.address)
    })

    it("Should have contracts deployed.", async function () {
        expect(!!instaConnectorsV2.address).to.be.true;
        expect(!!connector.address).to.be.true;
        expect(!!(await masterSigner.getAddress())).to.be.true;
    });

    describe("DSA wallet setup", function () {
        it("Should build DSA v2", async function () {
            dsaWallet0 = await buildDSAv2(wallet0.address)
            expect(!!dsaWallet0.address).to.be.true;
        });

        it("Deposit AVAX into DSA wallet", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
        });
    });

    describe("Main", function () {
        console.log(1)
        it("Should deposit AVAX in Compound", async function () {
            const amount = ethers.utils.parseEther("1") // 1 ETH
            const spells = [
                {
                    connector: connectorName,
                    method: "deposit",
                    args: ['0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', '0xC22F01ddc8010Ee05574028528614634684EC29e', amount, 0, 0]
                }
            ]
            console.log(1)
            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            console.log(1)
            const receipt = await tx.wait()
            console.log(1)
            expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(ethers.utils.parseEther("9"));
            console.log(1)
        });

        it("Should borrow and payback DAI from TraderJoe", async function () {
            const amount = ethers.utils.parseEther("100") // 100 DAI
            const setId = "83478237"
            const spells = [
                {
                    connector: connectorName,
                    method: "borrow",
                    args: ["DAI-A", amount, 0, setId]
                },
                {
                    connector: connectorName,
                    method: "payback",
                    args: ["DAI-A", 0, setId, 0]
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            const receipt = await tx.wait()
            expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(ethers.utils.parseEther("9"));
        });

        it("Should deposit all AVAX in TraderJoe", async function () {
            const spells = [
                {
                    connector: connectorName,
                    method: "deposit",
                    args: ["AVAX-A", constants.max_value, 0, 0]
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            const receipt = await tx.wait()
            expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(ethers.utils.parseEther("0"));
        });

        it("Should withdraw all AVAX from TraderJoe", async function () {
            const spells = [
                {
                    connector: connectorName,
                    method: "withdraw",
                    args: ["AVAX-A", constants.max_value, 0, 0]
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            const receipt = await tx.wait()
            expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
        });
    })
})
