import hre from "hardhat";
import { expect } from "chai";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2AaveV1, ConnectV2AaveV1__factory } from "../../../typechain";
import { parseEther } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { tokens } from "../../../scripts/tests/mainnet/tokens";
import { constants } from "../../../scripts/constant/constant";
import { addLiquidity } from "../../../scripts/tests/addLiquidity";
const { ethers } = hre;
import type { Signer, Contract } from "ethers";

describe("Aave V1", function () {
  const connectorName = "AAVEV1-TEST-A";

  let wallet0: Signer, wallet1: Signer;
  let dsaWallet0: Contract;
  let instaConnectorsV2: Contract;
  let connector: any;
  let masterSigner: Signer;

  before(async () => {
    try {
      await hre.network.provider.request({
        method: "hardhat_reset",
        params: [
          {
            forking: {
              // @ts-ignore
              jsonRpcUrl: hre.config.networks.hardhat.forking.url,
              blockNumber: 12796965,
            },
          },
        ],
      });
      [wallet0, wallet1] = await ethers.getSigners();
      masterSigner = await getMasterSigner();
      instaConnectorsV2 = await ethers.getContractAt(
        abis.core.connectorsV2,
        addresses.core.connectorsV2
      );
      connector = await deployAndEnableConnector({
        connectorName,
        contractArtifact: ConnectV2AaveV1__factory,
        signer: masterSigner,
        connectors: instaConnectorsV2,
      });
      console.log("Connector address", connector.address);
    } catch (err) {
      console.log("error", err);
    }
  });

  it("should have contracts deployed", async () => {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
      dsaWallet0 = await buildDSAv2(wallet0.getAddress());
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: parseEther("10"),
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        parseEther("10")
      );
    });
  });

  describe("Main", function () {
    it("should deposit ETH in Aave V1", async function () {
      const amt = parseEther("1");
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [tokens.eth.address, amt, 0, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.eq(
        parseEther("9")
      );
    });

    it("Should borrow and payback DAI from Aave V1", async function () {
      const amt = parseEther("100"); // 100 DAI

      // add a little amount of dai to cover any shortfalls
      await addLiquidity("dai", dsaWallet0.address, parseEther("1"));

      const spells = [
        {
          connector: connectorName,
          method: "borrow",
          args: [tokens.dai.address, amt, 0, 0],
        },
        {
          connector: connectorName,
          method: "payback",
          // FIXME: we need to pass max_value because of roundoff/shortfall errors
          args: [tokens.dai.address, constants.max_value, 0, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("9")
      );
    });

    it("Should deposit all ETH in Aave V1", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [tokens.eth.address, constants.max_value, 0, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("0")
      );
    });

    it("Should withdraw all ETH from Aave V1", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: [tokens.eth.address, constants.max_value, 0, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseEther("10")
      );
    });
  });
});
