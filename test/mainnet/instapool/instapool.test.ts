import { expect } from "chai";
import hre from "hardhat";
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector"
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2"
import { encodeSpells } from "../../../scripts/tests/encodeSpells"
import encodeFlashcastData from "../../../scripts/tests/encodeFlashcastData"
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner"

import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";
import type { Signer, Contract } from "ethers";
import { ConnectV2Compound__factory } from "../../../typechain";

describe("Instapool", function () {
  const connectorName = "COMPOUND-TEST-A"

  let dsaWallet0: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;

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
            blockNumber: 13300000,
          },
        },
      ],
    });
    masterSigner = await getMasterSigner()
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2Compound__factory,
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

    it("Deposit ETH into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
    });
  });

  describe("Main", function () {

    it("Should take 100 ETH flashloan from Instapool", async function () {
      const amount = ethers.utils.parseEther("1") // 1 ETH
      const flashloanAmount = ethers.utils.parseEther("100") // 100 ETH
      const ethAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

      const IdOne = "2878734423"
      const IdTwo = "783243246"

      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: ["ETH-A", flashloanAmount, 0, IdOne]
        },
        {
          connector: connectorName,
          method: "withdraw",
          args: ["ETH-A", amount, IdOne, IdTwo]
        },
        {
          connector: "INSTAPOOL-A",
          method: "flashPayback",
          args: [ethAddress, flashloanAmount, IdTwo, 0],
        }
      ]

      const calldata = encodeFlashcastData(spells);

      const spells2 = [
        {
          connector: "INSTAPOOL-A",
          method: "flashBorrowAndCast",
          args: [
            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
            flashloanAmount,
            0, // route
            calldata,
          ],
        }
      ]

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells2), wallet1.address)
      const receipt = await tx.wait()
    });
  })
})
