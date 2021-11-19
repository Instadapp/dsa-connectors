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
    const account = "0x36cc7B13029B5DEe4034745FB4F24034f3F2ffc6";
    [owner, add1, add2] = await ethers.getSigners();

    const tokenArtifact = await artifacts.readArtifact(
      "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20"
    );

    await network.provider.send("hardhat_setBalance", [
      owner.address,
      ethers.utils.parseEther("10.0").toHexString(),
    ]);

    await network.provider.send("hardhat_setBalance", [
      account,
      ethers.utils.parseEther("10.0").toHexString(),
    ]);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [account],
    });

    const signer = await ethers.getSigner(account);

    const token = new ethers.Contract(
      WETH_ADDR,
      tokenArtifact.abi,
      ethers.provider
    );

    console.log((await token.balanceOf(account)).toString());

    await token
      .connect(signer)
      .transfer(owner.address, ethers.utils.parseEther("10"));

    await hre.network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [account],
    });

    UniswapSellBeta = await ethers.getContractFactory(
      "UniswapSellBetaArbitrum"
    );
    uniswapSellBeta = await UniswapSellBeta.deploy();
    await uniswapSellBeta.deployed();
  });

  it("Should have contracts deployed.", async function() {
    expect(uniswapSellBeta.address).to.exist;
  });

  it("Should Perfrom a swap", async () => {
    const tx = await uniswapSellBeta.sell(
      WETH_ADDR,
      USDC_ADDR,
      3000,
      ethers.utils.parseUnits("1.0", 18),
      0,
      true
    );
    console.log(tx);
  });
});
