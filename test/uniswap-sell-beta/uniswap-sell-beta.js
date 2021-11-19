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

const USDT_ADDR = "0xdac17f958d2ee523a2206206994597c13d831ec7";
const DAI_ADDR = "0x6b175474e89094c44da98b954eedeac495271d0f";

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
    expect(uniswapSellBeta.address).to.be.true;
  });

  it("Should Perfrom a swap", async () => {
    const tx = await uniswapSellBeta.sell(
      USDT_ADDR,
      DAI_ADDR,
      ethers.utils.parseEther("1.0"),
      ethers.utils.parseEther("10.0"),
      true,
      { value: ethers.utils.parseEther("10.0") }
    );
    console.log(tx);
  });
});
