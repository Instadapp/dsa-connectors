const { expect } = require("chai");
const hre = require("hardhat");
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle

const deployAndEnableConnector = require("../../scripts/deployAndEnableConnector.js")
const buildDSAv2 = require("../../scripts/buildDSAv2")
const encodeSpells = require("../../scripts/encodeSpells.js")
const encodeFlashcastData = require("../../scripts/encodeFlashcastData.js")
const getMasterSigner = require("../../scripts/getMasterSigner")
const addLiquidity = require("../../scripts/addLiquidity");

const addresses = require("../../scripts/constant/addresses");
const abis = require("../../scripts/constant/abis");
const constants = require("../../scripts/constant/constant");
const tokens = require("../../scripts/constant/tokens");
const { abi: nftManagerAbi } = require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json")

const connectV2UniswapV3Artifacts = require("../../artifacts/contracts/mainnet/connectors/uniswapV3/main.sol/ConnectV2UniswapV3.json");
const { eth } = require("../../scripts/constant/tokens");
const { BigNumber } = require("ethers");

const FeeAmount = {
    LOW: 500,
    MEDIUM: 3000,
    HIGH: 10000,
}

const TICK_SPACINGS = {
    500: 10,
    3000: 60,
    10000: 200
}

const USDT_ADDR = "0xdac17f958d2ee523a2206206994597c13d831ec7"
const DAI_ADDR = "0x6b175474e89094c44da98b954eedeac495271d0f"

let tokenIds = []
let liquidities = []
const abiCoder = ethers.utils.defaultAbiCoder

describe("UniswapV3", function () {
    const connectorName = "UniswapV3-v1"

    let dsaWallet0
    let masterSigner;
    let instaConnectorsV2;
    let connector;
    let nftManager;

    const wallets = provider.getWallets()
    const [wallet0, wallet1, wallet2, wallet3] = wallets
    before(async () => {
        masterSigner = await getMasterSigner(wallet3)
        instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
        nftManager = await ethers.getContractAt(nftManagerAbi, "0xC36442b4a4522E871399CD717aBDD847Ab11FE88");
        connector = await deployAndEnableConnector({
            connectorName,
            contractArtifact: connectV2UniswapV3Artifacts,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })
        console.log("Connector address", connector.address)
    })

    it("Should have contracts deployed.", async function () {
        expect(!!instaConnectorsV2.address).to.be.true;
        expect(!!connector.address).to.be.true;
        expect(!!masterSigner.address).to.be.true;
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

        it("Should mint successfully", async function () {
            const ethAmount = ethers.utils.parseEther("0.1") // 1 ETH
            const daiAmount = ethers.utils.parseEther("400") // 1 ETH
            const usdtAmount = ethers.utils.parseEther("400") / Math.pow(10, 12) // 1 ETH
            const ethAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

            const getIds = ["0", "0"]
            const setId = "0"

            const spells = [
                {
                    connector: connectorName,
                    method: "mint",
                    args: [
                        DAI_ADDR,
                        ethAddress,
                        FeeAmount.MEDIUM,
                        getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
                        getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
                        daiAmount,
                        ethAmount,
                        "500000000000000000",
                        getIds,
                        setId
                    ],
                },
                {
                    connector: connectorName,
                    method: "mint",
                    args: [
                        DAI_ADDR,
                        USDT_ADDR,
                        FeeAmount.MEDIUM,
                        getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
                        getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
                        daiAmount,
                        usdtAmount,
                        "300000000000000000",
                        getIds,
                        setId
                    ],
                },
                {
                    connector: connectorName,
                    method: "mint",
                    args: [
                        ethAddress,
                        USDT_ADDR,
                        FeeAmount.MEDIUM,
                        getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
                        getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
                        ethAmount,
                        usdtAmount,
                        "300000000000000000",
                        getIds,
                        setId
                    ],
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            let receipt = await tx.wait()
            let castEvent = new Promise((resolve, reject) => {
                dsaWallet0.on('LogCast', (origin, sender, value, targetNames, targets, eventNames, eventParams, event) => {
                    const params = abiCoder.decode(["uint256", "uint256", "uint256", "uint256", "int24", "int24"], eventParams[0]);
                    const params1 = abiCoder.decode(["uint256", "uint256", "uint256", "uint256", "int24", "int24"], eventParams[2]);
                    tokenIds.push(params[0]);
                    tokenIds.push(params1[0]);
                    liquidities.push(params[1]);
                    event.removeListener();

                    resolve({
                        eventNames,
                    });
                });

                setTimeout(() => {
                    reject(new Error('timeout'));
                }, 60000)
            });

            let event = await castEvent

            const data = await nftManager.positions(tokenIds[0])

            expect(data.liquidity).to.be.equals(liquidities[0]);
        })

        it("Should deposit successfully", async function () {
            const daiAmount = ethers.utils.parseEther("400") // 1 ETH
            const ethAmount = ethers.utils.parseEther("0.1") // 1 ETH
            const usdtAmount = ethers.utils.parseEther("400") / Math.pow(10, 12) // 1 ETH
            const ethAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

            const getIds = ["0", "0"]
            const setId = "0"

            const spells = [
                {
                    connector: connectorName,
                    method: "deposit",
                    args: [
                        tokenIds[0],
                        daiAmount,
                        ethAmount,
                        "500000000000000000",
                        getIds,
                        setId
                    ],
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            const receipt = await tx.wait()

            let castEvent = new Promise((resolve, reject) => {
                dsaWallet0.on('LogCast', (origin, sender, value, targetNames, targets, eventNames, eventParams, event) => {
                    const params = abiCoder.decode(["uint256", "uint256", "uint256", "uint256"], eventParams[0]);
                    liquidities[0] = liquidities[0].add(params[1]);
                    event.removeListener();

                    resolve({
                        eventNames,
                    });
                });

                setTimeout(() => {
                    reject(new Error('timeout'));
                }, 60000)
            });

            let event = await castEvent

            const data = await nftManager.positions(tokenIds[0])
            expect(data.liquidity).to.be.equals(liquidities[0]);
        })

        it("Should withdraw successfully", async function () {

            const getId = "0"
            const setIds = ["0", "0"]

            const data = await nftManager.positions(tokenIds[0])
            let data1 = await nftManager.positions(tokenIds[1])

            const spells = [
                {
                    connector: connectorName,
                    method: "withdraw",
                    args: [
                        tokenIds[0],
                        data.liquidity,
                        0,
                        0,
                        getId,
                        setIds
                    ],
                },
                {
                    connector: connectorName,
                    method: "withdraw",
                    args: [
                        0,
                        data1.liquidity,
                        0,
                        0,
                        getId,
                        setIds
                    ],
                },
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            const receipt = await tx.wait()

            data1 = await nftManager.positions(tokenIds[1])
            expect(data1.liquidity.toNumber()).to.be.equals(0);
        })

        it("Should collect successfully", async function () {

            const ethAmount = ethers.utils.parseEther("0.2") // 1 ETH
            const daiAmount = ethers.utils.parseEther("800") // 1 ETH
            const getIds = ["0", "0"]
            const setIds = ["0", "0"]

            const spells = [
                {
                    connector: connectorName,
                    method: "collect",
                    args: [
                        tokenIds[0],
                        daiAmount,
                        ethAmount,
                        getIds,
                        setIds
                    ],
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            const receipt = await tx.wait()
        })

        it("Should burn successfully", async function () {

            const spells = [
                {
                    connector: connectorName,
                    method: "burn",
                    args: [
                        tokenIds[0]
                    ],
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            const receipt = await tx.wait()
        })
    })
})

const getMinTick = (tickSpacing) => Math.ceil(-887272 / tickSpacing) * tickSpacing
const getMaxTick = (tickSpacing) => Math.floor(887272 / tickSpacing) * tickSpacing
