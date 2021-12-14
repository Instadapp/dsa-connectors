import {Contract, Signer} from "ethers";


const { expect } = require("chai");
const hre = require("hardhat");
const { abis } = require("../../../scripts/constant/abis");
const { addresses } = require("../../../scripts/tests/polygon/addresses");
const { tokens }  = require("../../../scripts/tests/polygon/tokens");
const { deployAndEnableConnector } = require("../../../scripts/tests/deployAndEnableConnector");
const { getMasterSigner } = require("../../../scripts/tests/getMasterSigner");
const { buildDSAv2 } = require("../../../scripts/tests/buildDSAv2");
import {ConnectV2QiDaoPolygon__factory} from "../../../typechain";
const { parseEther } = require("@ethersproject/units");
const { encodeSpells } = require("../../../scripts/tests/encodeSpells");
const { vaults } = require("./vaults");
const { addLiquidity } = require("../../../scripts/tests/addLiquidity");
const { ethers } = hre;

describe("QiDao", function() {
  const connectorName = "QIDAO-TEST-A";

  let wallet0: Signer, wallet1: Signer;
  let dsaWallet0: Contract;
  let instaConnectorsV2: Contract;
  let connector: Contract;
  let masterSigner: Signer;

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
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
      contractArtifact: ConnectV2QiDaoPolygon__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
  });

  it("should have contracts deployed", async () => {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!await masterSigner.getAddress()).to.be.true;
  });

  describe("DSA wallet setup", function() {
    it("Should build DSA v2", async function() {
      dsaWallet0 = await buildDSAv2(await wallet0.getAddress());
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH into DSA wallet", async function() {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: parseEther("10"),
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        parseEther("10")
      );
    });
    it("Deposit LINK into DSA wallet", async function() {
      await addLiquidity("link", dsaWallet0.address, parseEther("100"));
    })
  });

  describe("Main", function() {
    it("should create a MATIC vault in QiDao and deposit MATIC into that vault", async function() {
      const amt = parseEther("5");
      const brwAmt = parseEther("1");
      const setVaultId = "13571113";
      const spells = [
        {
          connector: connectorName,
          method: "createVault",
          args: [vaults.matic.address, setVaultId],
        },
        {
          connector: connectorName,
          method: "deposit",
          args: [tokens.matic.address, vaults.matic.address, 0, amt, setVaultId, 0, 0, 0],
        },
        {
          connector: connectorName,
          method: "borrow",
          args: [vaults.matic.address, 0, brwAmt, setVaultId, 0, 0 , 0]
        },
        {
          connector: connectorName,
          method: "payback",
          args: [vaults.matic.address, 0, brwAmt, setVaultId, 0, 0 , 0],
        },
        {
          connector: connectorName,
          method: "withdraw",
          args: [tokens.matic.address, vaults.matic.address, 0, amt.mul(995).div(1000), setVaultId, 0, 0, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), await wallet1.getAddress());

      await tx.wait();

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.eq(
        parseEther("9.975")
      );
    });


    it("should create a LINK vault in QiDao and deposit LINK into that vault", async function() {
      const amt = parseEther("50");
      const brwAmt = parseEther("10");
      const setVaultId = "13571113";
      const spells = [
        {
          connector: connectorName,
          method: "createVault",
          args: [vaults.link.address, setVaultId],
        },
        {
          connector: connectorName,
          method: "deposit",
          args: [tokens.link.address, vaults.link.address, 0, amt, setVaultId, 0, 0, 0],
        },
        {
          connector: connectorName,
          method: "borrow",
          args: [vaults.link.address, 0, brwAmt, setVaultId, 0, 0 , 0]
        },
        {
          connector: connectorName,
          method: "payback",
          args: [vaults.link.address, 0, brwAmt, setVaultId, 0, 0 , 0],
        },
        {
          connector: connectorName,
          method: "withdraw",
          args: [tokens.link.address, vaults.link.address, 0, amt.mul(995).div(1000), setVaultId, 0, 0, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), await wallet1.getAddress());

      await tx.wait();

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.eq(
        parseEther("9.975")
      );
    });
  });
});
