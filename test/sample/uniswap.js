const { expect } = require("chai");
const hre = require("hardhat");
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle;
const deployAndEnableConnector = require("../../scripts/deployAndEnableConnector.js");
const buildDSAv2 = require("../../scripts/buildDSAv2");
const encodeSpells = require("../../scripts/encodeSpells.js");

const addresses = require("../../scripts/constant/addresses");
const abis = require("../../scripts/constant/abis");

const FeeAmount = {
  LOW: 500,
  MEDIUM: 3000,
  HIGH: 10000,
};

const TICK_SPACINGS = {
  500: 10,
  3000: 60,
  10000: 200,
};

const USDT_ADDR = "0xdac17f958d2ee523a2206206994597c13d831ec7";
const DAI_ADDR = "0x6b175474e89094c44da98b954eedeac495271d0f";

describe("UniswapV3", function() {
  const connectorName = "UniswapV3-v1";
  let dsaWallet0;
  let masterSigner;
  let instaConnectorsV2;
  let connector;
  let nftManager;

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;
  before(async () => {
    masterSigner = await getMasterSigner(wallet3);
    instaConnectorsV2 = await ethers.getContractAt(
      abis.core.connectorsV2,
      addresses.core.connectorsV2
    );
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: connectV2UniswapV3Artifacts,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
    console.log("Connector address", connector.address);
  });

  it("Should have contracts deployed.", async function() {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!masterSigner.address).to.be.true;
  });

  describe("DSA wallet setup", function() {
    it("Should build DSA v2", async function() {
      dsaWallet0 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Perfrom a swap", async function() {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10"),
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseEther("10")
      );

      await addLiquidity(
        "usdt",
        dsaWallet0.address,
        ethers.utils.parseEther("100000")
      );
    });
  });
});
