import { expect } from "chai";
import hre from "hardhat";
const { waffle, ethers } = hre;
const { provider } = waffle

import {deployAndEnableConnector} from "../../../scripts/tests/deployAndEnableConnector";
import {buildDSAv2} from "../../../scripts/tests/buildDSAv2";
import {encodeSpells} from "../../../scripts/tests/encodeSpells";
import {getMasterSigner} from "../../../scripts/tests/getMasterSigner";
import {addLiquidity} from "../../../scripts/tests/addLiquidity";
import {addresses} from "../../../scripts/tests/mainnet/addresses";
import {abis} from "../../../scripts/constant/abis";

import { ConnectV2Sushiswap__factory, ConnectV2Sushiswap, ConnectV2SushiswapIncentive, ConnectV2SushiswapIncentive__factory } from "../../../typechain";
import { Contract, Signer } from "ethers";

const DAI_ADDR = "0x6b175474e89094c44da98b954eedeac495271d0f"
const WETH_ADDR = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

describe("Sushiswap", function () {
    const connectorName = "Sushiswap-v1"
    const incentiveConnectorName = "Sushiswp-Incentive-v1"

    let dsaWallet0: Contract;
    let masterSigner: Signer;
    let instaConnectorsV2: Contract;
    let connector: Contract, connectorIncentive;

    const wallets = provider.getWallets()
    const [wallet0, wallet1, wallet2, wallet3] = wallets
    before(async () => {
        await hre.network.provider.request({
            method: "hardhat_reset",
            params: [
                {
                    forking: {
                        // @ts-ignore
                        jsonRpcUrl: hre.config.networks.hardhat.forking.url,
                        blockNumber: 13005785,
                    },
                },
            ],
        });
        masterSigner = await getMasterSigner()
        instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
        connector = await deployAndEnableConnector({
            connectorName,
            contractArtifact: ConnectV2Sushiswap__factory,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })
        console.log("Connector address", connector.address)

        connectorIncentive = await deployAndEnableConnector({
            connectorName: incentiveConnectorName,
            contractArtifact: ConnectV2SushiswapIncentive__factory,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })
        console.log("Incentive Connector address", connectorIncentive.address)
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

        it("Deposit ETH & DAI into DSA wallet", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));

            await addLiquidity("dai", dsaWallet0.address, ethers.utils.parseEther("100000"));
        });

        it("Deposit ETH & USDT into DSA wallet", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));

            await addLiquidity("usdt", dsaWallet0.address, ethers.utils.parseEther("100000"));
        });
    });

    describe("Main", function () {
        const data = {
            poolId: 0,
            version: 0, 
            lpToken: ethers.constants.AddressZero
        }

        it("Should deposit successfully", async function () {
            const ethAmount = ethers.utils.parseEther("2") // 1 ETH
            const daiUnitAmount = ethers.utils.parseEther("4000") // 1 ETH
            const ethAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

            const getId = "0"
            const setId = "0"

            const spells = [
                {
                    connector: connectorName,
                    method: "deposit",
                    args: [
                        ethAddress,
                        DAI_ADDR,
                        ethAmount,
                        daiUnitAmount,
                        "500000000000000000",
                        getId,
                        setId
                    ],
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            await tx.wait()

            describe("Incentive", () => {
                it("Should deposit successfully", async () => {
                    const getId = 0
                    const setId = 0
                    const spells = [
                        {
                            connector: incentiveConnectorName,
                            method: "deposit",
                            args: [
                                WETH_ADDR,
                                DAI_ADDR,
                                ethers.utils.parseEther("10"),
                                getId,
                                setId,
                                data
                            ]
                        }
                    ]

                    const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address)
                    await tx.wait();
                })

                it("Should harvest successfully", async () => {
                    const setId = 0
                    const spells = [
                        {
                            connector: incentiveConnectorName,
                            method: "harvest",
                            args: [
                                WETH_ADDR,
                                DAI_ADDR,
                                setId,
                                data
                            ]
                        }
                    ]

                    const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address)
                    await tx.wait();
                })

                it("Should harvest and withdraw successfully", async () => {
                    const getId = 0
                    const setId = 0
                    const spells = [
                        {
                            connector: incentiveConnectorName,
                            method: "withdrawAndHarvest",
                            args: [
                                WETH_ADDR,
                                DAI_ADDR,
                                ethers.utils.parseEther("1"),
                                getId,
                                setId,
                                data
                            ]
                        }
                    ]

                    const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address)
                    await tx.wait();
                })

                it("Should withdraw successfully", async () => {
                    const getId = 0
                    const setId = 0
                    const spells = [
                        {
                            connector: incentiveConnectorName,
                            method: "withdraw",
                            args: [
                                WETH_ADDR,
                                DAI_ADDR,
                                ethers.utils.parseEther("1"),
                                getId,
                                setId,
                                data
                            ]
                        }
                    ]

                    const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address)
                    await tx.wait();
                })
            })
        }).timeout(10000000000);

        it("Should buy successfully", async function () {
            const ethAmount = ethers.utils.parseEther("0.1") // 1 ETH
            const daiUnitAmount = ethers.utils.parseEther("4000") // 1 ETH
            const ethAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

            const getId = "0"
            const setId = "0"

            const spells = [
                {
                    connector: connectorName,
                    method: "buy",
                    args: [
                        ethAddress,
                        DAI_ADDR,
                        ethAmount,
                        daiUnitAmount,
                        getId,
                        setId
                    ]
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            let receipt = await tx.wait()
        });
    });
}) 
