const { expect } = require("chai");
const hre = require("hardhat");
const { waffle, ethers } = hre;
const { provider, deployContract } = waffle

const deployAndEnableConnector = require("../../scripts/deployAndEnableConnector.js")
const buildDSAv2 = require("../../scripts/buildDSAv2")
const encodeSpells = require("../../scripts/encodeSpells.js")
const getMasterSigner = require("../../scripts/getMasterSigner")
const addLiquidity = require("../../scripts/addLiquidity");

const addresses = require("../../scripts/constant/addresses");
const abis = require("../../scripts/constant/abis");
const { abi: nftManagerAbi } = require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json")

const connectV2UniswapStakerArtifacts = require("../../artifacts/contracts/mainnet/connectors/uniswapStaker/main.sol/ConnectV2UniswapV3Staker.json");
const connectV2UniswapV3Artifacts = require("../../artifacts/contracts/mainnet/connectors/uniswapV3/main.sol/ConnectV2UniswapV3.json");

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

const DAI_ADDR = "0x6b175474e89094c44da98b954eedeac495271d0f"
const ethAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

let tokenIds = []
const abiCoder = ethers.utils.defaultAbiCoder

describe("UniswapV3", function () {
    const connectorStaker = "UniswapStaker-v1"
    const connectorUniswap = "UniswapV3-v1"

    let dsaWallet0
    let masterSigner;
    let instaConnectorsV2;
    let connector;
    let startTime, endTime;

    const wallets = provider.getWallets()
    const [wallet0, wallet1, wallet2, wallet3] = wallets
    before(async () => {
        masterSigner = await getMasterSigner(wallet3)
        instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
        nftManager = await ethers.getContractAt(nftManagerAbi, "0xC36442b4a4522E871399CD717aBDD847Ab11FE88");
        connector = await deployAndEnableConnector({
            connectorName: connectorStaker,
            contractArtifact: connectV2UniswapStakerArtifacts,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })
        console.log("Connector address", connector.address)

        uniswapConnector = await deployAndEnableConnector({
            connectorName: connectorUniswap,
            contractArtifact: connectV2UniswapV3Artifacts,
            signer: masterSigner,
            connectors: instaConnectorsV2
        });
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

            await addLiquidity("dai", dsaWallet0.address, ethers.utils.parseEther("100000"));
            await addLiquidity("usdt", dsaWallet0.address, ethers.utils.parseEther("100000"));
        });
    });

    describe("Main", function () {
        const ethAmount = ethers.utils.parseEther("0.1") // 1 ETH
        const daiAmount = ethers.utils.parseEther("400") // 1 ETH

        it("Should mint successfully", async function () {
            const getIds = ["0", "0"]
            const setId = "0"

            const spells = [
                {
                    connector: connectorUniswap,
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
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            let receipt = await tx.wait()

            let castEvent = new Promise((resolve, reject) => {
                dsaWallet0.on('LogCast', (origin, sender, value, targetNames, targets, eventNames, eventParams, event) => {
                    const params = abiCoder.decode(["uint256", "uint256", "uint256", "uint256", "int24", "int24"], eventParams[0]);
                    tokenIds.push(params[0]);
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
        });

        it("Should create incentive successfully", async function () {
            const spells = [
                {
                    connector: connectorStaker,
                    method: "createIncentive",
                    args: [
                        ethAddress,
                        "1000",
                        dsaWallet0.address,
                        tokenIds[0],
                        ethers.utils.parseEther("0.01")
                    ],
                }]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            let receipt = await tx.wait()

            let castEvent = new Promise((resolve, reject) => {
                dsaWallet0.on('LogCast', (origin, sender, value, targetNames, targets, eventNames, eventParams, event) => {
                    const params = abiCoder.decode(["uint256", "uint256", "uint256", "uint256"], eventParams[0]);
                    event.removeListener();

                    resolve({ start: params[1], end: params[2] });
                });

                setTimeout(() => {
                    reject(new Error('timeout'));
                }, 60000)
            });

            let event = await castEvent
            startTime = event.start;
            endTime = event.end;
        });

        it("Should stake successfully", async function () {
            const spells = [
                {
                    connector: connectorStaker,
                    method: "deposit",
                    args: [
                        tokenIds[0]
                    ],
                },
                {
                    connector: connectorStaker,
                    method: "stake",
                    args: [
                        ethAddress,
                        startTime,
                        endTime,
                        dsaWallet0.address,
                        tokenIds[0]
                    ],
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            let receipt = await tx.wait()
        });

        it("Should claim rewards successfully", async function () {
            const spells = [
                {
                    connector: connectorStaker,
                    method: "claimRewards",
                    args: [
                        ethAddress,
                        dsaWallet0.address,
                        "1000",
                    ],
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            let receipt = await tx.wait()
        });

        it("Should unstake successfully", async function () {
            const spells = [
                {
                    connector: connectorStaker,
                    method: "unstake",
                    args: [
                        ethAddress,
                        startTime,
                        endTime,
                        dsaWallet0.address,
                        tokenIds[0]
                    ],
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            let receipt = await tx.wait()
        });
    })
})

const getMinTick = (tickSpacing) => Math.ceil(-887272 / tickSpacing) * tickSpacing
const getMaxTick = (tickSpacing) => Math.floor(887272 / tickSpacing) * tickSpacing
