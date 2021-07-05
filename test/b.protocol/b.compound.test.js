const { expect } = require("chai");
const hre = require("hardhat");
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle

const deployAndEnableConnector = require("../../scripts/deployAndEnableConnector.js")
const buildDSAv2 = require("../../scripts/buildDSAv2")
const encodeSpells = require("../../scripts/encodeSpells.js")
const getMasterSigner = require("../../scripts/getMasterSigner")

const addresses = require("../../scripts/constant/addresses");
const abis = require("../../scripts/constant/abis");
const constants = require("../../scripts/constant/constant");
const tokens = require("../../scripts/constant/tokens");

const connectV2CompoundArtifacts = require("../../artifacts/contracts/mainnet/connectors/b.protocol/compound/main.sol/ConnectV1BCompound.json")

describe("B.Compound", function () {
    const connectorName = "B.COMPOUND-TEST-A"
    
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
            contractArtifact: connectV2CompoundArtifacts,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })
        console.log("Connector address", connector.address)
  })

  it("Should have contracts deployed.", async function () {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!masterSigner.address).to.be.true;
    expect(await connector.name()).to.be.equal("B.Compound-v1.0");
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

    it("Should deposit ETH in Compound", async function () {
        const amount = ethers.utils.parseEther("1") // 1 ETH
        const spells = [
            {
                connector: connectorName,
                method: "deposit",
                args: ["ETH-A", amount, 0, 0]
            }
        ]

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()
        expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(ethers.utils.parseEther("9"));
    });

    it("Should borrow and payback DAI from Compound", async function () {
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

    it("Should deposit all ETH in Compound", async function () {
        const spells = [
            {
                connector: connectorName,
                method: "deposit",
                args: ["ETH-A", constants.max_value, 0, 0]
            }
        ]

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()
        expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(ethers.utils.parseEther("0"));
    });

    it("Should withdraw all ETH from Compound", async function () {
        const spells = [
            {
                connector: connectorName,
                method: "withdraw",
                args: ["ETH-A", constants.max_value, 0, 0]
            }
        ]

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()
        expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
    });
  })
})
