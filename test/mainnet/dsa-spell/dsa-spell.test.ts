import hre from "hardhat";
import axios from "axios";
import { expect } from "chai";
const { ethers } = hre; //check
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2DSASpell__factory } from "../../../typechain";
import type { Signer, Contract } from "ethers";
import BigNumber from "bignumber.js";

describe("DSA Spell", function () {
  const connectorName = "dsa-spell-test";

  let dsaWallet0: any;
  let dsaWallet1: any;
  let dsaWallet2: any;
  let walletB: any;
  let wallet0: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url
          }
        }
      ]
    });
    [wallet0] = await ethers.getSigners();

    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2DSASpell__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
    console.log("\tConnector address", connector.address);
  });

  it("Should have contracts deployed.", async function () {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
      dsaWallet0 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet0.address).to.be.true;
      walletB = await ethers.getSigner(dsaWallet0.address);
      dsaWallet1 = await buildDSAv2(dsaWallet0.address);
      expect(!!dsaWallet1.address).to.be.true;
      console.log(`\t${dsaWallet1.address}`);
    });

    it("Deposit eth into DSA wallet 0", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
    });

    it("Deposit eth into DSA wallet 1", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet1.address,
        value: ethers.utils.parseEther("10")
      });

      expect(await ethers.provider.getBalance(dsaWallet1.address)).to.be.gte(ethers.utils.parseEther("10"));
    });
  });

  describe("Main", function () {
    let ETH = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
    let USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    let usdc = new ethers.Contract(USDC, abis.basic.erc20);
    let aETH = "0x030bA81f1c18d280636F32af80b9AAd02Cf0854e";
    let aEth = new ethers.Contract(aETH, abis.basic.aToken);
    var abi = [
      "function withdraw(address,uint256,address,uint256,uint256)",
      "function deposit(address,uint256,uint256,uint256)",
      "function borrow(address,uint256,uint256,uint256,uint256)"
    ];
    function getCallData(spell: string, params: any) {
      var iface = new ethers.utils.Interface(abi);
      let data = iface.encodeFunctionData(spell, params);
      return ethers.utils.hexlify(data);
    }

    it("should cast spells", async function () {
      async function getArg(connectors: any, spells: any, params: any) {
        let datas = [];
        for (let i = 0; i < connectors.length; i++) {
          datas.push(getCallData(spells[i], params[i]));
        }
        return [dsaWallet1.address, connectors, datas];
      }

      let connectors = ["BASIC-A"];
      let methods = ["withdraw"];
      let params = [
        [ETH, ethers.utils.parseEther("2"), dsaWallet0.address, 0, 0],
      ];
      let arg = await getArg(connectors, methods, params);

      const spells = [
        {
          connector: connectorName,
          method: "castOnDSA",
          args: arg
        }
      ];
      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), await wallet0.getAddress());
      const receipt = await tx.wait();
    });

    it("should check balances after cast on DSA", async function () {
      expect(await ethers.provider.getBalance(dsaWallet1.address)).to.be.lte(new BigNumber(8).multipliedBy(1e18).toString());
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        new BigNumber(12).multipliedBy(1e18).toString()
      );
    });

    it("should cast spell on the first successful", async function () {
      async function getArg(connectors: any, spells: any, params: any) {
        let datas = [];
        for (let i = 0; i < connectors.length; i++) {
          datas.push(getCallData(spells[i], params[i]));
        }
        return [connectors, datas];
      }

      let connectors = ["AAVE-V2-A", "AAVE-V1-A"];
      let methods = ["deposit", "deposit"];
      let params = [
        [ETH, ethers.utils.parseEther("10"), 0, 0],
        [ETH, ethers.utils.parseEther("10"), 0, 0]
      ];
      let arg = await getArg(connectors, methods, params);
      const spells = [
        {
          connector: connectorName,
          method: "castAny",
          args: arg
        }
      ];
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), await wallet0.getAddress());
      const receipt = await tx.wait();
    });

    it("should check balances after spells on DSA", async function () {
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        new BigNumber(2).multipliedBy(1e18).toString()
      );
      expect(await aEth.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.gte(
        new BigNumber(10).multipliedBy(1e18).toString()
      );
    });
  });
});
