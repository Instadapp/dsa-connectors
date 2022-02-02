import { expect } from "chai";
import hre from "hardhat";
const { web3, deployments, waffle, ethers } = hre; //check
const { provider, deployContract } = waffle

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector"
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2"
import { encodeSpells } from "../../../scripts/tests/encodeSpells"
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner"
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2BLiquity__factory } from "../../../typechain";
import type { Signer, Contract } from "ethers";
import { addresses } from "../../../scripts/tests/mainnet/addresses";

const LUSD_WHALE = "0x66017D22b0f8556afDd19FC67041899Eb65a21bb" // stability pool
const BAMM_ADDRESS = "0x0d3AbAA7E088C2c82f54B2f47613DA438ea8C598"

describe("B.Liquity", function () {
  const connectorName = "B.LIQUITY-TEST-A"

  let dsaWallet0: any;
  let dsaWallet1: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;
  let manager: Contract;
  let vat: Contract;
  let lusd: Contract;
  let bammToken: Contract;
  let stabilityPool: Contract;

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
            blockNumber: 12996875,
          },
        },
      ],
    });
    masterSigner = await getMasterSigner()
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2BLiquity__factory,
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
    expect(!!(await masterSigner.getAddress())).to.be.true;
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

function veryClose(n1: any, n2: any) {
  n1 = web3.utils.toBN(n1)
  n2 = web3.utils.toBN(n2)

  let _10000 = web3.utils.toBN(10000)
  let _9999 = web3.utils.toBN(9999)

  if (n1.mul(_10000).lt(n2.mul(_9999))) return false
  if (n2.mul(_10000).lt(n1.mul(_9999))) return false

  return true
}
