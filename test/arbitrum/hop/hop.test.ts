import { expect } from "chai";
import hre, { ethers } from "hardhat";
import type { Signer, Contract } from "ethers";
import { BigNumber } from "bignumber.js";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { addresses } from "../../../scripts/tests/arbitrum/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { abis } from "../../../scripts/constant/abis";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { parseEther } from "ethers/lib/utils";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { ConnectV2HopArbitrum__factory, IERC20__factory } from "../../../typechain";

let account = "0xa067668661c84476afcdc6fa5d758c4c01c34352";
const mnemonic = "test test test test test test test test test test test junk";
const WETH = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1";
const connectorName = "HOP-X";
let signer: any, wallet0: any;

describe("Hop connector", function () {
  let dsaWallet0: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;

  const wallet = ethers.Wallet.fromMnemonic(mnemonic);
  const token = new ethers.Contract(WETH, IERC20__factory.abi);

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            //@ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url
            // blockNumber: 9333600
          }
        }
      ]
    });
    masterSigner = await getMasterSigner();
    [wallet0] = await ethers.getSigners();

    await hre.network.provider.send("hardhat_setBalance", [account, ethers.utils.parseEther("10").toHexString()]);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [account]
    });

    signer = await ethers.getSigner(account);

    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2HopArbitrum__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
  });

  describe("Deployment", async () => {
    it("Should set correct name", async () => {
      expect(await connector.name()).to.eq("Hop-v1.0");
    });
  });

  describe("DSA wallet setup", async () => {
    it("Should build DSA v2", async () => {
      dsaWallet0 = await buildDSAv2(wallet.address);
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("5")
      });

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("5"));
    });
  });

  describe("Main", async () => {
    it("should send ETH successfully", async () => {
      const deadline = new BigNumber(Date.now()).dividedBy(1000).plus(604800).toFixed(0);
      const bridgeParams = [
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
        "0x33ceb27b39d2Bb7D2e61F7564d3Df29344020417",
        dsaWallet0.address,
        "137",
        parseEther("1"),
        parseEther("0.01"),
        parseEther("0.8"),
        deadline,
        parseEther("0.8"),
        deadline
      ];

      const spells = [
        {
          connector: connectorName,
          method: "bridge",
          args: [bridgeParams, "0"]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet.getAddress());
      await tx.wait();
    });

    it("should send WETH successfully", async () => {
      const deadline = new BigNumber(Date.now()).dividedBy(1000).plus(604800).toFixed(0);
      await token.connect(signer).transfer(dsaWallet0.address, ethers.utils.parseEther("10"));

      const bridgeParams = [
        "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
        "0x33ceb27b39d2Bb7D2e61F7564d3Df29344020417",
        dsaWallet0.address,
        "137",
        parseEther("1"),
        parseEther("0.01"),
        parseEther("0.8"),
        deadline,
        parseEther("0.8"),
        deadline
      ];

      const spells = [
        {
          connector: connectorName,
          method: "bridge",
          args: [bridgeParams, "0"]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet.getAddress());
      await tx.wait();
    });
  });
});
