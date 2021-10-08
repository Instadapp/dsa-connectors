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

const connectV2SushiswapArtifacts = require("../../artifacts/contracts/mainnet/connectors/sushiswap/main.sol/ConnectV2Sushiswap.json");
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

describe("Sushiswap", function () {
    const connectorName = "Sushiswap-v1"

    let dsaWallet0
    let masterSigner;
    let instaConnectorsV2;
    let connector;

    const wallets = provider.getWallets()
    const [wallet0, wallet1, wallet2, wallet3] = wallets
    before(async () => {
        await hre.network.provider.request({
            method: "hardhat_reset",
            params: [
                {
                    forking: {
                        jsonRpcUrl: hre.config.networks.hardhat.forking.url,
                        blockNumber: 13005785,
                    },
                },
            ],
        });
        masterSigner = await getMasterSigner(wallet3)
        instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
        connector = await deployAndEnableConnector({
            connectorName,
            contractArtifact: connectV2SushiswapArtifacts,
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

        it("Should deposit successfully", async function () {
            const ethAmount = ethers.utils.parseEther("0.1") // 1 ETH
            const daiUnitAmount = ethers.utils.parseEther("4000") // 1 ETH
            const usdtAmount = ethers.utils.parseEther("400") / Math.pow(10, 12) // 1 ETH
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
            let receipt = await tx.wait()
            // let castEvent = new Promise((resolve, reject) => {
            //     dsaWallet0.on('LogCast', (origin, sender, value, targetNames, targets, eventNames, eventParams, event) => {
            //         const params = abiCoder.decode(["uint256", "uint256", "uint256", "uint256", "int24", "int24"], eventParams[0]);
            //         const params1 = abiCoder.decode(["uint256", "uint256", "uint256", "uint256", "int24", "int24"], eventParams[2]);
            //         tokenIds.push(params[0]);
            //         tokenIds.push(params1[0]);
            //         liquidities.push(params[1]);
            //         event.removeListener();

            //         resolve({
            //             eventNames,
            //         });
            //     });

            //     setTimeout(() => {
            //         reject(new Error('timeout'));
            //     }, 60000)
            // });

            // let event = await castEvent

            // const data = await nftManager.positions(tokenIds[0])

            // expect(data.liquidity).to.be.equals(liquidities[0]);
        }).timeout(10000000000);

        it("Should withdraw successfully", async function () {
            const ethAmount = ethers.utils.parseEther("0.1") // 1 ETH
            const ethAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

            const getId = "0"
            const setIds = ["0", "0"]

            const spells = [
                {
                    connector: connectorName,
                    method: "withdraw",
                    args: [
                        ethAddress,
                        DAI_ADDR,
                        ethAmount,
                        0,
                        0,
                        getId,
                        setIds
                    ]
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            let receipt = await tx.wait()
        });

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