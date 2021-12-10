import { BigNumberish } from "@ethersproject/bignumber";
import { Contract } from "@ethersproject/contracts";
import { expect } from "chai";
import hre, { artifacts } from "hardhat";
const { ethers } = hre;

const USDC_ADDR = "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8";
const WETH_ADDR = "0x82af49447d8a07e3bd95bd0d56f35241523fbab1";

describe("Uniswap-sell-beta", function () {
  let UniswapSellBeta, uniswapSellBeta: Contract;

  async function setBalance(address: string) {
    await hre.network.provider.send("hardhat_setBalance", [
      address,
      ethers.utils.parseEther("10.0").toHexString(),
    ]);
  }

  async function impersonate(owner: string, account: any, token0: string, decimals: BigNumberish | undefined) {
    const tokenArtifact = await artifacts.readArtifact(
      "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20"
    );

    setBalance(owner);
    setBalance(account);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [account],
    });

    const signer = await ethers.getSigner(account);

    const token = new ethers.Contract(
      token0,
      tokenArtifact.abi,
      ethers.provider
    );

    // console.log((await token.balanceOf(account)).toString());

    await token
      .connect(signer)
      .transfer(owner, ethers.utils.parseUnits("10", decimals));

    await hre.network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [account],
    });
  }

  beforeEach(async () => {
    const account0 = "0xa067668661c84476afcdc6fa5d758c4c01c34352";
    const account1 = "0x0db3fe3b770c95a0b99d1ed6f2627933466c0dd8";

    const [owner, add1, add2] = await ethers.getSigners();
    await impersonate(owner.address, account1, USDC_ADDR, 6);
    await impersonate(owner.address, account0, WETH_ADDR, 18);

    UniswapSellBeta = await ethers.getContractFactory(
      "ConnectV2UniswapSellBeta"
    );
    uniswapSellBeta = await UniswapSellBeta.deploy();
    await uniswapSellBeta.deployed();
  });

  it("Should have contracts deployed.", async function () {
    expect(uniswapSellBeta.address).to.exist;
  });

  it("Should swap WETH with USDC", async () => {
    const [owner, add1, add2] = await ethers.getSigners();

    const tokenArtifact = await artifacts.readArtifact(
      "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20"
    );

    const token = new ethers.Contract(
      WETH_ADDR,
      tokenArtifact.abi,
      ethers.provider
    );

    const signer = await ethers.getSigner(owner.address);

    await token
      .connect(signer)
      .transfer(uniswapSellBeta.address, ethers.utils.parseUnits("10.0", 18));

    const tx = await uniswapSellBeta.sell(
      WETH_ADDR,
      USDC_ADDR,
      3000,
      ethers.utils.parseUnits("10.0", 18),
      0
    );
    // console.log(tx);
  });

  it("Should swap USDC with WETH", async () => {
    const [owner, add1, add2] = await ethers.getSigners();

    const tokenArtifact = await artifacts.readArtifact(
      "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20"
    );

    const token = new ethers.Contract(
      USDC_ADDR,
      tokenArtifact.abi,
      ethers.provider
    );

    const signer = await ethers.getSigner(owner.address);

    await token
      .connect(signer)
      .transfer(uniswapSellBeta.address, ethers.utils.parseUnits("10.0", 6));

    const tx = await uniswapSellBeta.sell(
      USDC_ADDR,
      WETH_ADDR,
      3000,
      ethers.utils.parseUnits("10.0", 6),
      0
    );
    // console.log(tx);
  });
});
