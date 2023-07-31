import { expect } from "chai";
import hre from "hardhat";
const { waffle, ethers } = hre;
const { provider, deployContract } = waffle;

import { Signer, Contract } from "ethers";
import { BigNumber } from "bignumber.js";

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { tokens } from "../../../scripts/tests/mainnet/tokens";
import { abis } from "../../../scripts/constant/abis";
import { constants } from "../../../scripts/constant/constant";
import { ConnectV2CRV__factory } from "../../../typechain";
import { MaxUint256 } from "@uniswap/sdk-core";
import { USDC_OPTIMISTIC_KOVAN } from "@uniswap/smart-order-router";

describe("CRV USD", function () {
  const connectorName = "CRV_USD-TEST-A";
  const market = "0xc3d688B66703497DAA19211EEdff47f25384cdc3";
  const base = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
  const wst_whale = "0x248cCBf4864221fC0E840F29BB042ad5bFC89B5c";
  const wethWhale = "0x78bB3aEC3d855431bd9289fD98dA13F9ebB7ef15";

  const ABI = [
    "function balanceOf(address account) public view returns (uint256)",
    "function approve(address spender, uint256 amount) external returns(bool)",
    "function transfer(address recipient, uint256 amount) external returns (bool)"
  ];
  const wethContract = new ethers.Contract(tokens.weth.address, ABI);
  const baseContract = new ethers.Contract(base, ABI);
  const linkContract = new ethers.Contract(tokens.wbtc.address, ABI);
  const crvUSD = new ethers.Contract(tokens.crvusd.address, ABI)
  const wstETH = new ethers.Contract(tokens.wsteth.address, ABI)

  let dsaWallet0: any;
  let dsaWallet1: any;
  let dsaWallet2: any;
  let dsaWallet3: any;
  let wallet: any;
  let dsa0Signer: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;
  let signer: any;
  let sfrxSigner: any;

//   const comet = new ethers.Contract(market, cometABI);

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            //@ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            // blockNumber: 15444500
          }
        }
      ]
    });
    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2CRV__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
    console.log("Connector address", connector.address);

    await hre.network.provider.send("hardhat_setBalance", [wst_whale, ethers.utils.parseEther("10").toHexString()]);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [wst_whale]
    });

    signer = await ethers.getSigner(wst_whale);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [wethWhale]
    });
    sfrxSigner = await ethers.getSigner(wethWhale);
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
      dsaWallet1 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet1.address).to.be.true;
      dsaWallet2 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet2.address).to.be.true;
      dsaWallet3 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet3.address).to.be.true;
      wallet = await ethers.getSigner(dsaWallet0.address);
      expect(!!dsaWallet1.address).to.be.true;
    });

    it("Deposit ETH into DSA wallet", async function () {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [wallet.address]
      });

      dsa0Signer = await ethers.getSigner(wallet.address);
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
      await wallet0.sendTransaction({
        to: dsaWallet1.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
      await wallet0.sendTransaction({
        to: dsaWallet3.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));

      await wstETH.connect(signer).transfer(dsaWallet0.address, ethers.utils.parseEther('10'))
    });
  });

  describe("Main", function () {
    //deposit asset
    it("Create Loan", async function () {
      const bal = await wstETH.balanceOf(dsaWallet0.address)
      console.log('--------balance of weseth---------', bal.toString())
      // const spells = [
      //   {
      //     connector: connectorName,
      //     method: "createLoan",
      //     args: [tokens.wsteth.address, ethers.utils.parseEther('1'), ethers.utils.parseEther('100'), 10]
      //   }
      // ];

      // const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      // const receipt = await tx.wait();

      // console.log("-----balance of CRV-USD-----", (await crvUSD.balanceOf(wallet0.address)).toString())
      // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(ethers.utils.parseEther("5"));
      // expect((await comet.connect(signer).userCollateral(dsaWallet0.address, tokens.weth.address)).balance).to.be.gte(
      //   ethers.utils.parseEther("5")
      // );
    });

  });
});
