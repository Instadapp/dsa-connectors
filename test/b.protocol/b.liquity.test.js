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

const connectorLiquityArtifacts = require("../../artifacts/contracts/mainnet/connectors/b.protocol/liquity/main.sol/ConnectV2BLiquity.json")

const LUSD_WHALE = "0x66017D22b0f8556afDd19FC67041899Eb65a21bb" // stability pool

const BAMM_ADDRESS = "0x0d3AbAA7E088C2c82f54B2f47613DA438ea8C598"

describe("B.Liquity", function () {
    const connectorName = "B.LIQUITY-TEST-A"
    
    let dsaWallet0;
    let dsaWallet1;   
    let masterSigner;
    let instaConnectorsV2;
    let connector;
    let manager;
    let vat;
    let lusd;
    let bammToken;
    let stabilityPool;
    
    const wallets = provider.getWallets()
    const [wallet0, wallet1, wallet2, wallet3] = wallets
    before(async () => {
        masterSigner = await getMasterSigner(wallet3)
        instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
        connector = await deployAndEnableConnector({
            connectorName,
            contractArtifact: connectorLiquityArtifacts,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })

        lusd = await ethers.getContractAt("../artifacts/contracts/mainnet/common/interfaces.sol:TokenInterface", "0x5f98805A4E8be255a32880FDeC7F6728C6568bA0")
        bammToken = await ethers.getContractAt("../artifacts/contracts/mainnet/connectors/b.protocol/liquity/interface.sol:BAMMLike", BAMM_ADDRESS)
        stabilityPool = await ethers.getContractAt("../artifacts/contracts/mainnet/connectors/b.protocol/liquity/interface.sol:StabilityPoolLike", "0x66017D22b0f8556afDd19FC67041899Eb65a21bb")        

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
    expect(await connector.name()).to.be.equal("B.Liquity-v1");
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
        dsaWallet0 = await buildDSAv2(wallet0.address)
        expect(!!dsaWallet0.address).to.be.true;

        dsaWallet1 = await buildDSAv2(wallet1.address)
        expect(!!dsaWallet1.address).to.be.true;        
    });

    it("Deposit LUSD into DSA wallet", async function () {
        await hre.network.provider.request({
          method: "hardhat_impersonateAccount",
          params: [LUSD_WHALE],
        });

        const signer = await hre.ethers.provider.getSigner(LUSD_WHALE);
        await lusd.connect(signer).transfer(dsaWallet0.address, ethers.utils.parseEther("100000"))

        expect(await lusd.balanceOf(dsaWallet0.address)).to.equal(ethers.utils.parseEther("100000"));
    });
  });

  describe("Main", function () {
    it("should deposit 10k LUSD", async function () {
        const totalSupplyBefore = await bammToken.totalSupply();
        const lusdBalanceBefore = await stabilityPool.getCompoundedLUSDDeposit(BAMM_ADDRESS);
        const amount = ethers.utils.parseEther("10000");
        const spells = [
            {
                connector: connectorName,
                method: "deposit",
                args: [amount, 0, 0, 0]
            }
        ]

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        const expectedBalance = totalSupplyBefore.mul(amount).div(lusdBalanceBefore)
        expect(veryClose(expectedBalance, await bammToken.balanceOf(dsaWallet0.address))).to.be.true
    });

    it("should deposit all LUSD", async function () {
      const totalSupplyBefore = await bammToken.totalSupply();
      const lusdBalanceBefore = await stabilityPool.getCompoundedLUSDDeposit(BAMM_ADDRESS);
      const amount = web3.utils.toBN("2").pow(web3.utils.toBN("256")).sub(web3.utils.toBN("1"));
      const balanceBefore = await bammToken.balanceOf(dsaWallet0.address)

      const spells = [
          {
              connector: connectorName,
              method: "deposit",
              args: [amount, 0, 0, 0]
          }
      ]

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
      const receipt = await tx.wait()

      const expectedBalance = (totalSupplyBefore.mul(ethers.utils.parseEther("90000")).div(lusdBalanceBefore)).add(balanceBefore)
      expect(veryClose(expectedBalance, await bammToken.balanceOf(dsaWallet0.address))).to.be.true
    });
    
    it("should withdraw half of the shares", async function () {
      const balanceBefore = await bammToken.balanceOf(dsaWallet0.address)
      const halfBalance = balanceBefore.div("2")

      const spells = [
          {
              connector: connectorName,
              method: "withdraw",
              args: [halfBalance, 0, 0, 0]
          }
      ]

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
      const receipt = await tx.wait()

      expect(veryClose(halfBalance, await bammToken.balanceOf(dsaWallet0.address))).to.be.true
      expect(veryClose(ethers.utils.parseEther("50000"), await lusd.balanceOf(dsaWallet0.address))).to.be.true      
    });

    it("should withdraw all the shares", async function () {
      const amount = web3.utils.toBN("2").pow(web3.utils.toBN("256")).sub(web3.utils.toBN("1"));

      const spells = [
          {
              connector: connectorName,
              method: "withdraw",
              args: [amount, 0, 0, 0]
          }
      ]

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
      const receipt = await tx.wait()

      expect(veryClose(ethers.utils.parseEther("100000"), await lusd.balanceOf(dsaWallet0.address))).to.be.true      
    });    
  })
})

function veryClose(n1, n2) {
    n1 = web3.utils.toBN(n1)
    n2 = web3.utils.toBN(n2)

    _10000 = web3.utils.toBN(10000)
    _9999 = web3.utils.toBN(9999)    

    if(n1.mul(_10000).lt(n2.mul(_9999))) return false
    if(n2.mul(_10000).lt(n1.mul(_9999))) return false

    return true
}
