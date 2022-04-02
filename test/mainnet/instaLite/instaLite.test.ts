import hre from "hardhat";
import { expect } from "chai";
const { ethers } = hre; //check
import { BigNumber } from "bignumber.js";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { addLiquidity } from "../../../scripts/tests/addLiquidity";
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2InstaLiteVault1__factory } from "../../../typechain";
// import lido_abi from "./abi.json";
import type { Signer, Contract } from "ethers";
import { parseEther } from "ethers/lib/utils";

describe("instaLite", function () {
  const connectorName = "instaLite-test";

  let dsaWallet0: Contract;
  let wallet0: Signer, wallet1: Signer;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;

  before(async () => {
    // await hre.network.provider.request({
    //   method: "hardhat_reset",
    //   params: [
    //     {
    //       forking: {
    //         // @ts-ignore
    //         jsonRpcUrl: hre.config.networks.hardhat.forking.url,
    //         blockNumber: 14334859
    //       },
    //     },
    //   ],
    // });
    [wallet0, wallet1] = await ethers.getSigners();
    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2InstaLiteVault1__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
    console.log("Connector address", connector.address);
  });

  it("Should have contracts deployed.", async function () {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
      dsaWallet0 = await buildDSAv2(await wallet0.getAddress());
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH  into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
    });
  });

  describe("Main", function () {
    it("should deposit the eth", async function () {
      const _amt = ethers.utils.parseEther("5");
      const ethAddr = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";
      const spells = [
        {
          connector: connectorName,
          method: "supply",
          args: ["0xc383a3833a87009fd9597f8184979af5edfad019", ethAddr, _amt, 0, [0, 0]]
        }
      ];
      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), await wallet1.getAddress());
      const receipt = await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.eq(parseEther("5"));
    });

    it("should withdraw", async function () {
      const _amt = ethers.utils.parseEther("1");
      const spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: ["0xc383a3833a87009fd9597f8184979af5edfad019", _amt, 0, [0, 0]]
        }
      ];
      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), await wallet1.getAddress());
      const receipt = await tx.wait();
    });
  });
});
