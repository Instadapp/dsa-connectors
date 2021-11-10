const { expect } = require("chai");
const hre = require("hardhat");
const { parseEther } = require("@ethersproject/units");

const ConnectV2AugmentedFinance = require("../../artifacts/contracts/mainnet/connectors/augmented-finance/v1/main.sol/ConnectV2AugmentedFinance.json");
const abis = require("../../scripts/constant/abis");
const addresses = require("../../scripts/constant/addresses");
const deployAndEnableConnector = require("../../scripts/deployAndEnableConnector");
const getMasterSigner = require("../../scripts/getMasterSigner");
const buildDSAv2 = require("../../scripts/buildDSAv2");
const encodeSpells = require("../../scripts/encodeSpells");
const tokens = require("../../scripts/constant/tokens");
const constants = require("../../scripts/constant/constant");
const addLiquidity = require("../../scripts/addLiquidity");

const { ethers } = hre;

describe("Augmented Finance V1", () => {
  const CONNECTOR_NAME = "AugmentedFinance-TEST-A";

  let wallet0, wallet1, dsaWallet, mainWallet;

  before(async () => {
    let instaConnectorsV2, connector;

    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 13575395,
          },
        },
      ],
    });

    [[wallet0, wallet1], mainWallet, instaConnectorsV2] = await Promise.all([
      ethers.getSigners(),
      getMasterSigner(),
      ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2),
    ]);

    [dsaWallet, connector] = await Promise.all([
      buildDSAv2(wallet0.address),
      deployAndEnableConnector({
        connectorName: CONNECTOR_NAME,
        contractArtifact: ConnectV2AugmentedFinance,
        signer: mainWallet,
        connectors: instaConnectorsV2,
      }),
    ]);

    await wallet0.sendTransaction({
      to: dsaWallet.address,
      value: parseEther("10"),
    });

    console.log("Connector address:", connector.address);
  });

  it("should deposit ETH", async () => {
    const amount = parseEther("1");
    const spells = [
      {
        connector: CONNECTOR_NAME,
        method: "deposit",
        args: [tokens.eth.address, amount, 0, 0],
      },
    ];

    const tx = await dsaWallet
      .connect(wallet0)
      .cast(...encodeSpells(spells), wallet1.address);
    await tx.wait();

    const balance = await ethers.provider.getBalance(dsaWallet.address);
    expect(balance).to.eq(parseEther("9"));
  });

  it("should borrow and repay DAI", async () => {
    const amount = parseEther("100");
    const setId = 1;
    const spells = [
      {
        connector: CONNECTOR_NAME,
        method: "borrow",
        args: [tokens.dai.address, amount, 2, 0, setId],
      },
      {
        connector: CONNECTOR_NAME,
        method: "payback",
        args: [tokens.dai.address, amount, 2, setId, 0],
      },
    ];

    const tx = await dsaWallet
      .connect(wallet0)
      .cast(...encodeSpells(spells), wallet1.address);
    await tx.wait();

    const balance = await ethers.provider.getBalance(dsaWallet.address);
    expect(balance).to.be.lte(parseEther("9"));
  });

  it("should borrow and payback max DAI", async () => {
    const amount = parseEther("100");
    const spells = [
      {
        connector: CONNECTOR_NAME,
        method: "borrow",
        args: [tokens.dai.address, amount, 2, 0, 0],
      },
      {
        connector: CONNECTOR_NAME,
        method: "payback",
        args: [tokens.dai.address, constants.max_value, 2, 0, 0],
      },
    ];
    await addLiquidity("dai", dsaWallet.address, parseEther("1"));

    const tx = await dsaWallet
      .connect(wallet0)
      .cast(...encodeSpells(spells), wallet1.address);
    await tx.wait();

    const balance = await ethers.provider.getBalance(dsaWallet.address);
    expect(balance).to.be.lte(parseEther("9"));
  });

  it("should deposit and withdraw all ETH", async () => {
    const setId = "1";
    const spells = [
      {
        connector: CONNECTOR_NAME,
        method: "deposit",
        args: [tokens.eth.address, constants.max_value, 0, setId],
      },
      {
        connector: CONNECTOR_NAME,
        method: "withdraw",
        args: [tokens.eth.address, constants.max_value, setId, 0],
      },
    ];

    const tx = await dsaWallet
      .connect(wallet0)
      .cast(...encodeSpells(spells), wallet1.address);
    await tx.wait();

    const balance = await ethers.provider.getBalance(dsaWallet.address);
    expect(balance).to.be.gte(parseEther("9"));
  });
});
