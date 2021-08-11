const { expect } = require("chai");
const hre = require("hardhat");
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle

const deployAndEnableConnector = require("../../scripts/deployAndEnableConnector.js")
const buildDSAv2 = require("../../scripts/buildDSAv2")
const encodeSpells = require("../../scripts/encodeSpells.js")
const encodeFlashcastData = require("../../scripts/encodeFlashcastData.js")
const getMasterSigner = require("../../scripts/getMasterSigner")

const addresses = require("../../scripts/constant/addresses");
const abis = require("../../scripts/constant/abis");
const constants = require("../../scripts/constant/constant");
const tokens = require("../../scripts/constant/tokens");

const connectV2UniswapV3Artifacts = require("../../artifacts/contracts/mainnet/connectors/uniswapV3/main.sol/ConnectV2UniswapV3.json")

describe("UniswapV3", function () {
    const connectorName = "UniswapV3-v1"

    let dsaWallet0
    let masterSigner;
    let instaConnectorsV2;
    let connector;

    const wallets = provider.getWallets()
    const [wallet0, wallet1, wallet2, wallet3] = wallets
    before(async () => {
        masterSigner = await getMasterSigner(wallet3)
        instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
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

        it("Deposit ETH into DSA wallet", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
        });
    });

    describe("Main", function () {

        it("Should mint successfully", async function () {
            const amount = ethers.utils.parseEther("1") // 1 ETH
            const ethAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

            const IdOne = "2878734423"
            const IdTwo = "783243246"

            const spells2 = [
                {
                    connector: connectorName,
                    method: "mint",
                    args: [
                        { tokenA: ethAddress, tokenB: "0x6b175474e89094c44da98b954eedeac495271d0f", fee: "3000", tickUpper: "887220", tickLower: "-887220", amtA: "15", amtB: "15", slippage: "0" }, IdOne, IdTwo
                    ],
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells2), wallet1.address)
            const receipt = await tx.wait()
        })
    })
})
