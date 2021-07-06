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

const connectorMakerArtifacts = require("../../artifacts/contracts/mainnet/connectors/b.protocol/makerdao/main.sol/ConnectV1BMakerDAO.json")

describe("B.Maker", function () {
    const connectorName = "B.MAKER-TEST-A"
    
    let dsaWallet0
    let masterSigner;
    let instaConnectorsV2;
    let connector;
    let managerWeb3Contract;
    let vatWeb3Contract;
    let daiWeb3Contract;
    
    const wallets = provider.getWallets()
    const [wallet0, wallet1, wallet2, wallet3] = wallets
    before(async () => {
        masterSigner = await getMasterSigner(wallet3)
        instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
        connector = await deployAndEnableConnector({
            connectorName,
            contractArtifact: connectorMakerArtifacts,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })

        const cdpManagerArtifact = await hre.artifacts.readArtifact("BManagerLike");
        const vatArtifact = await hre.artifacts.readArtifact("../artifacts/contracts/mainnet/connectors/b.protocol/makerdao/interface.sol:VatLike");

        managerWeb3Contract = new web3.eth.Contract(cdpManagerArtifact.abi, "0x3f30c2381CD8B917Dd96EB2f1A4F96D91324BBed")
        vatWeb3Contract = new web3.eth.Contract(vatArtifact.abi, await managerWeb3Contract.methods.vat().call())
        daiWeb3Contract = new web3.eth.Contract(abis.basic.erc20, tokens.dai.address)

        console.log("Connector address", connector.address)
  })

  it("test veryClose.", async function () {
    expect(veryClose(1000001, 1000000)).to.be.true
    expect(veryClose(1000000, 1000001)).to.be.true    
    expect(veryClose(1003000, 1000001)).to.be.false
    expect(veryClose(1000001, 1000300)).to.be.false        
  });

  it("Should have contracts deployed.", async function () {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!masterSigner.address).to.be.true;
    expect(await connector.name()).to.be.equal("B.MakerDAO-v1.0");
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
    let vault
    let ilk
    let urn

    it("Should open ETH-A vault Maker", async function () {
        vault = Number(await managerWeb3Contract.methods.cdpi().call()) + 1
        const spells = [
            {
                connector: connectorName,
                method: "open",
                args: ["ETH-A"]
            }
        ]

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()
        
        expect(await managerWeb3Contract.methods.owns(vault).call()).to.be.equal(dsaWallet0.address)

        ilk = await managerWeb3Contract.methods.ilks(vault).call()
        expect(ilk).to.be.equal("0x4554482d41000000000000000000000000000000000000000000000000000000")

        urn = await managerWeb3Contract.methods.urns(vault).call()        
    });

    it("Should deposit", async function () {
        const amount = ethers.utils.parseEther("7") // 7 ETH
        const setId = "83478237"

        const spells = [
            {
                connector: connectorName,
                method: "deposit",
                args: [vault, amount, 0, setId]
            }
        ]

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("3"))

        const urnData = await vatWeb3Contract.methods.urns(ilk, urn).call()
        expect(urnData[0]).to.be.equal(amount) // ink
        expect(urnData[1]).to.be.equal("0") // art        

    });

    it("Should withdraw", async function () {
        const amount = ethers.utils.parseEther("1") // 1 ETH
        const setId = "83478237"

        const spells = [
            {
                connector: connectorName,
                method: "withdraw",
                args: [vault, amount, 0, setId]
            }
        ]

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("4"))

        const urnData = await vatWeb3Contract.methods.urns(ilk, urn).call()
        expect(urnData[0]).to.be.equal(ethers.utils.parseEther("6")) // ink
        expect(urnData[1]).to.be.equal("0") // art        

    });

    it("Should borrow", async function () {
        const amount = ethers.utils.parseEther("6000") // 6000 dai
        const setId = "83478237"

        const spells = [
            {
                connector: connectorName,
                method: "borrow",
                args: [vault, amount, 0, setId]
            }
        ]

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        const urnData = await vatWeb3Contract.methods.urns(ilk, urn).call()
        expect(urnData[0]).to.be.equal(ethers.utils.parseEther("6")) // ink
        expect(urnData[1]).to.be.equal(await daiToArt(vatWeb3Contract, ilk, amount)) // art
        
        expect(await daiWeb3Contract.methods.balanceOf(dsaWallet0.address).call()).to.be.equal(amount)
    });

    it("Should repay", async function () {
        const amount = ethers.utils.parseEther("500") // 500 dai
        const setId = "83478237"

        const spells = [
            {
                connector: connectorName,
                method: "payback",
                args: [vault, amount, 0, setId]
            }
        ]

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        const urnData = await vatWeb3Contract.methods.urns(ilk, urn).call()
        expect(urnData[0]).to.be.equal(ethers.utils.parseEther("6")) // ink
        expect(urnData[1]).to.be.equal(await daiToArt(vatWeb3Contract, ilk, ethers.utils.parseEther("5500"))) // art        
        expect(await daiWeb3Contract.methods.balanceOf(dsaWallet0.address).call()).to.be.equal(ethers.utils.parseEther("5500"))
    });

    it("Should depositAndBorrow", async function () {
        const borrowAmount = ethers.utils.parseEther("1000") // 500 dai
        const depositAmount = ethers.utils.parseEther("1") // 1 dai
        
        const setId = "83478237"

        const spells = [
            {
                connector: connectorName,
                method: "depositAndBorrow",
                args: [vault, depositAmount, borrowAmount, 0, 0, 0, 0]
            }
        ]

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        const urnData = await vatWeb3Contract.methods.urns(ilk, urn).call()
        expect(urnData[0]).to.be.equal(ethers.utils.parseEther("7")) // ink
        expect(await daiWeb3Contract.methods.balanceOf(dsaWallet0.address).call()).to.be.equal(ethers.utils.parseEther("6500"))
        // calculation is not precise as the jug was dripped
        expect(veryClose(urnData[1], await daiToArt(vatWeb3Contract, ilk, ethers.utils.parseEther("6500")))).to.be.true    
        //expect(urnData[1]).to.be.equal(await daiToArt(vatWeb3Contract, ilk, ethers.utils.parseEther("6500"))) // art        
        expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("1"))        
    });    
  })
})

async function daiToArt(vatWeb3Contract, ilk, dai) {
    const ilks = await vatWeb3Contract.methods.ilks(ilk).call()
    const rate = ilks[1] // second parameter
    const _1e27 = ethers.utils.parseEther("1000000000") // 1e9 * 1e18
    const art = dai.mul(_1e27).div(rate)

    return art.add(1)
}

function veryClose(n1, n2) {
    n1 = web3.utils.toBN(n1)
    n2 = web3.utils.toBN(n2)

    _10000 = web3.utils.toBN(10000)
    _9999 = web3.utils.toBN(9999)    

    if(n1.mul(_10000).lt(n2.mul(_9999))) return false
    if(n2.mul(_10000).lt(n1.mul(_9999))) return false

    return true
}
