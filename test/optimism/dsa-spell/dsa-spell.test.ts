import hre from "hardhat";
import axios from "axios";
import { expect } from "chai";
const { ethers } = hre; //check
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/optimism/addresses";
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2DSASpellOptimism__factory } from "../../../typechain";
import type { Signer, Contract } from "ethers";

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
      contractArtifact: ConnectV2DSASpellOptimism__factory,
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
    var abi = [
      "function withdraw(address,uint256,address,uint256,uint256)",
      "function deposit(address,uint256,uint256,uint256)"
    ];
    function getCallData(spell: string, params: any) {
      var iface = new ethers.utils.Interface(abi);
      let data = iface.encodeFunctionData(spell, params);
      return data;
    }

    it("should cast spells", async function () {
      async function getArg() {
        let basicParams = [ETH, ethers.utils.parseEther("2"), dsaWallet0.address, 0, 0];
        let dataBasic = ethers.utils.hexlify(await getCallData("withdraw", basicParams));
        let datas = [dataBasic];

        let connectors = ["BASIC-A"];

        return [dsaWallet1.address, connectors, datas];
      }

      let arg = await getArg();
      const spells = [
        {
          connector: connectorName,
          method: "castOnDSA",
          args: arg
        }
      ];
      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), await wallet0.getAddress());
      const receipt = await tx.wait();

      expect(await ethers.provider.getBalance(dsaWallet1.address)).to.be.lte(ethers.utils.parseEther("8"));
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("12"));
    });

    it("should retry spells", async function () {
      async function getArg() {
        let basicParams = [ETH, ethers.utils.parseEther("1"), 0, 0];
        let dataBasic = ethers.utils.hexlify(await getCallData("deposit", basicParams));
        let basicWithdraw = [ETH, ethers.utils.parseEther("2"), dsaWallet1.address, 0, 0];
        let dataWithdraw = ethers.utils.hexlify(await getCallData("withdraw", basicWithdraw));
        let datas = [dataBasic, dataWithdraw];

        let connectors = ["BASIC-A", "BASIC-A"];

        return [connectors, datas];
      }

      let arg = await getArg();
      const spells = [
        {
          connector: connectorName,
          method: "retrySpell",
          args: arg
        }
      ];
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), await wallet0.getAddress(), { value: ethers.utils.parseEther("1") });
      const receipt = await tx.wait();

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(ethers.utils.parseEther("11"));
      expect(await ethers.provider.getBalance(dsaWallet1.address)).to.be.gte(ethers.utils.parseEther("10"));
    });
  });
});
