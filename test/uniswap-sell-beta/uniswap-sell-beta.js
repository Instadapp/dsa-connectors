const { expect } = require("chai");
const hre = require("hardhat");
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle;
const deployAndEnableConnector = require("../../scripts/deployAndEnableConnector.js");
const buildDSAv2 = require("../../scripts/buildDSAv2");
const encodeSpells = require("../../scripts/encodeSpells.js");

const addresses = require("../../scripts/constant/addresses");
const abis = require("../../scripts/constant/abis");

const UniswapSellBetaArtifacts = require("../../artifacts/contracts/arbitrum/connectors/uniswap-sell-beta/main.sol/UniswapSellBetaArbitrum.json");

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

const USDC_ADDR = "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8";
const WETH_ADDR = "0x82af49447d8a07e3bd95bd0d56f35241523fbab1";

describe("Uniswap-sell-beta", function() {
  let UniswapSellBeta, uniswapSellBeta;
  before(async () => {
    UniswapSellBeta = await ethers.getContractFactory(
      "UniswapSellBetaArbitrum"
    );
    uniswapSellBeta = await UniswapSellBeta.deploy();
    [owner, add1, add2] = await ethers.getSigners();
    await uniswapSellBeta.deployed();
  });

  it("Should have contracts deployed.", async function() {
    expect(uniswapSellBeta.address).to.exist;
  });

  it("Should Perfrom a swap", async () => {
    const tx = await uniswapSellBeta.sell(
      USDC_ADDR,
      WETH_ADDR,
      ethers.utils.parseUnits("0.000000000001"),
      ethers.utils.parseUnits("10.0"),
      ethers.utils.parseUnits("1.0"),
      true
    );
    console.log(tx);
  });
});
