import { expect } from "chai";
import hre, { network } from "hardhat";
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle;

import type { Signer, Contract } from "ethers";
import { parseEther, parseUnits } from "ethers/lib/utils";
import { BigNumber } from "bignumber.js";

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";
import { tokens } from "../../../scripts/tests/mainnet/tokens";
import { ConnectV2BasicERC4626__factory, IERC4626__factory, IERC20Minimal__factory } from "../../../typechain";

describe("BASIC-D", function () {
  const connectorName = "BASIC-D";

  let dsaWallet0: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;
  let wallet: any;

  const account = "0x075e72a5edf65f0a5f44699c7654c1a76941ddc8";
  const sDAIaddress = "0x83f20f44975d03b1b09e64809b757c47f942beea";
  let signer: any;

  const daiContract = new ethers.Contract(tokens.dai.address, IERC20Minimal__factory.abi, ethers.provider);
  const erc4626Contract = new ethers.Contract(sDAIaddress, IERC4626__factory.abi, ethers.provider);

  const wallets = provider.getWallets();
  const [wallet0] = wallets;

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking?.url,
            blockNumber: 17907926
          }
        }
      ]
    });

    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2BasicERC4626__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });

    console.log("Connector address", connector.address);

    await hre.network.provider.send("hardhat_setBalance", [account, ethers.utils.parseEther("10").toHexString()]);
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [account]
    });

    signer = await ethers.getSigner(account);
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
      wallet = await ethers.getSigner(dsaWallet0.address);
    });

    it("Deposit ETH into DSA wallet", async function () {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [wallet.address]
      });

      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });

      let txRes = await daiContract.connect(signer).transfer(dsaWallet0.address, ethers.utils.parseEther("10000"));
      await txRes.wait();
      // expect(await daiContract.balanceOf(dsaWallet0.address)).to.be.eq(ethers.utils.parseEther("10000"));
    });
  });

  describe("Main", function () {
    // it("Calculate Total Asset and Total Supply", async () => {
    //   const totalAsset = await erc4626Contract.totalAssets();
    //   const totalSupply = await erc4626Contract.totalSupply();
    //   console.log("totalAsset :>> ", totalAsset);
    //   console.log("totalSupply :>> ", totalSupply);
    // });
    it("should deposit asset to ERC4626", async () => {
      const assets = ethers.utils.parseEther("1");
      const previewDeposit = await erc4626Contract.previewDeposit(assets);
      console.log("previewDeposit :>> ", previewDeposit);

      const maxDeposit = await erc4626Contract.maxDeposit(dsaWallet0.address);

      let minSharesPerToken = ethers.utils.parseUnits("0.95");

      const beforebalance = await erc4626Contract.balanceOf(dsaWallet0.address);
      console.log("beforebalance :>> ", beforebalance);

      let spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [sDAIaddress, assets, minSharesPerToken, 0, 0]
        }
      ];

      let tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
      let receipt = await tx.wait();

      const afterbalance = await erc4626Contract.balanceOf(dsaWallet0.address);
      console.log("afterbalance :>> ", afterbalance);

      // In case of not satisfying min rate
      minSharesPerToken = ethers.utils.parseUnits("1");
      spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [sDAIaddress, assets, minSharesPerToken, 0, 0]
        }
      ];

      await expect(dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address)).to.be.reverted;

    });
    it("should mint asset to ERC4626", async () => {
      // const daiBalance = await daiContract.balanceOf(dsaWallet0.address);
      // console.log("daiBalance :>> ", daiBalance);
      const shares = ethers.utils.parseEther("1.03");
      const previewMint = await erc4626Contract.previewMint(shares);
      console.log("previewMint :>> ", previewMint);

      let maxTokenPerShares = ethers.utils.parseUnits("1.1");

      let spells = [
        {
          connector: connectorName,
          method: "mint",
          args: [sDAIaddress, previewMint, maxTokenPerShares, 0, 0]
        }
      ];

      let tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
      let receipt = await tx.wait();

      // In case of not satisfying max rate
      maxTokenPerShares = ethers.utils.parseUnits("1");

      spells = [
        {
          connector: connectorName,
          method: "mint",
          args: [sDAIaddress, previewMint, maxTokenPerShares, 0, 0]
        }
      ];

      await expect(dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address)).to.be.reverted;

    });
    it("should redeem asset to ERC4626", async () => {
      //   const shares = new BigNumber(1).toString()
      // const balance = await erc4626Contract.balanceOf(dsaWallet0.address);
      // console.log("balance :>> ", balance);

      const maxRedeem: BigNumber = await erc4626Contract.maxRedeem(dsaWallet0.address);
      console.log("maxRedeem :>> ", maxRedeem);

      const beforeUnderbalance = await daiContract.balanceOf(wallet0.address);
      console.log("beforeUnderbalance :>> ", beforeUnderbalance);

      const beforeVaultbalance = await erc4626Contract.balanceOf(wallet0.address);
      console.log("beforeVaultbalance :>> ", beforeVaultbalance);

      let minTokenPerShares = ethers.utils.parseUnits("1.01");

      const setId = "83478237";
      let spells = [
        {
          connector: connectorName,
          method: "redeem",
          args: [sDAIaddress, maxRedeem.div(2), minTokenPerShares, wallet0.address, 0, setId]
        }
      ];

      let tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
      let receipt = await tx.wait();

      const afterUnderbalance = await daiContract.balanceOf(wallet0.address);
      console.log("afterUnderbalance :>> ", afterUnderbalance);

      const afterVaultbalance = await erc4626Contract.balanceOf(wallet0.address);
      console.log("afterVaultbalance :>> ", afterVaultbalance);

      // In case of not satisfying min rate
      minTokenPerShares = ethers.utils.parseUnits("1.2");

      spells = [
        {
          connector: connectorName,
          method: "redeem",
          args: [sDAIaddress, maxRedeem.div(2), minTokenPerShares, wallet0.address, 0, setId]
        }
      ];

      await expect(dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address)).to.be.reverted;

    });
    it("should withdraw asset to ERC4626", async () => {
      const maxWithdraw: BigNumber = await erc4626Contract.maxWithdraw(dsaWallet0.address);
      console.log("maxWithdraw :>> ", maxWithdraw);

      const beforeUnderbalance = await daiContract.balanceOf(wallet0.address);
      console.log("beforeUnderbalance :>> ", beforeUnderbalance);

      const beforeVaultbalance = await erc4626Contract.balanceOf(wallet0.address);
      console.log("beforeVaultbalance :>> ", beforeVaultbalance);

      let maxSharesPerToken = ethers.utils.parseUnits("0.95");

      const setId = "83478237";
      let spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: [sDAIaddress, maxWithdraw, maxSharesPerToken, wallet0.address, 0, setId]
        }
      ];

      let tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
      let receipt = await tx.wait();

      const afterUnderbalance = await daiContract.balanceOf(wallet0.address);
      console.log("afterUnderbalance :>> ", afterUnderbalance);

      const afterVaultbalance = await erc4626Contract.balanceOf(wallet0.address);
      console.log("afterVaultbalance :>> ", afterVaultbalance);

      // In case of not satisfying min rate

      maxSharesPerToken = ethers.utils.parseUnits("1");

      spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: [sDAIaddress, maxWithdraw, maxSharesPerToken, wallet0.address, 0, setId]
        }
      ];

      await expect(dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address)).to.be.reverted;

    });
  });
});
