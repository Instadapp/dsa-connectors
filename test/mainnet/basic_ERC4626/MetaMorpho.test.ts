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
  const connectorName = "BASIC-D-Test";

  let dsaWallet0: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;
  let wallet: any;

  const account = "0x357dfdC34F93388059D2eb09996d80F233037cBa";
  const steakUSDCaddress = "0xBEEF01735c132Ada46AA9aA4c54623cAA92A64CB";
  const usdcAddress = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"

  const bbETHaddress = "0x38989BBA00BDF8181F4082995b3DEAe96163aC5D";

  const usdcAccount = "0x688344d10928ADC4BCf846E6Ed5EE0B2cAfE4786"
  let signer: any;
  let usdcSigner: any

  const ethContract = new ethers.Contract(tokens.eth.address, IERC20Minimal__factory.abi, ethers.provider);
  const usdcContract = new ethers.Contract(usdcAddress, IERC20Minimal__factory.abi, ethers.provider);
  const erc4626Contract = new ethers.Contract(steakUSDCaddress, IERC4626__factory.abi, ethers.provider);
  const bbETHContract = new ethers.Contract(bbETHaddress, IERC4626__factory.abi, ethers.provider);

  const wallets = provider.getWallets();
  const [wallet0, wallet1] = wallets;

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking?.url,
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

    await hre.network.provider.send("hardhat_setBalance", [usdcAccount, ethers.utils.parseEther("10").toHexString()]);
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [usdcAccount]
    });

    usdcSigner = await ethers.getSigner(usdcAccount);
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

      let txRes = await ethContract.connect(signer).transfer(dsaWallet0.address, ethers.utils.parseEther("1000"));
      await txRes.wait();
      // expect(await ethContract.balanceOf(dsaWallet0.address)).to.be.eq(ethers.utils.parseEther("10000"));
      await usdcContract.connect(usdcSigner).transfer(dsaWallet0.address, "1000000000")
    });
  });

  describe("Main", function () {
    // it("Calculate Total Asset and Total Supply", async () => {
    //   const totalAsset = await erc4626Contract.totalAssets();
    //   const totalSupply = await erc4626Contract.totalSupply();
    //   console.log("totalAsset :>> ", totalAsset);
    //   console.log("totalSupply :>> ", totalSupply);
    // });
    it("should deposit asset to steakUSDC", async () => {
      const assets = "500000000";
      
      // // Returns the amount of shares for assets
      // const previewDeposit = await erc4626Contract.previewDeposit(assets);
      // console.log("previewDeposit :>> ", previewDeposit.toString());

      const maxDeposit = await erc4626Contract.maxDeposit(dsaWallet0.address);

      let minSharesPerToken = ethers.utils.parseUnits("0.95");

      const beforebalance = await erc4626Contract.balanceOf(dsaWallet0.address);
      console.log("Share before balance :>> ", beforebalance.toString());

      let spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [steakUSDCaddress, assets, 0, 0, 0]
        },
        // {
        //   connector: connectorName,
        //   method: "redeem",
        //   args: [usdcAddress, ethers.utils.parseEther('500'), 0, 0, 0]
        // },
      ];

      let tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
    });

    it("should redeem steakUSDC", async () => {
      const balance = await erc4626Contract.balanceOf(dsaWallet0.address);
      console.log("Share balance :>> ", balance.toString());

      // Returns max Shares
      const maxRedeem: BigNumber = await erc4626Contract.maxRedeem(dsaWallet0.address);
      console.log("maxRedeem :>> ", maxRedeem.toString());


      const beforeVaultbalance = await erc4626Contract.balanceOf(dsaWallet0.address);
      console.log("beforeVaultbalance :>> ", beforeVaultbalance.toString());

      let spells = [
        {
          connector: connectorName,
          method: "redeem",
          args: [steakUSDCaddress, ethers.utils.parseEther('50'), 0, dsaWallet0.address, 0, 0]
        }
      ];

      let tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);

      const afterVaultbalance = await erc4626Contract.balanceOf(dsaWallet0.address);
      console.log("afterVaultbalance :>> ", afterVaultbalance.toString());
    });

    it("should deposit asset to steakUSDC with Max", async () => {

      const beforebalance = await erc4626Contract.balanceOf(dsaWallet0.address);
      console.log("Share before balance :>> ", beforebalance.toString());

      let spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [steakUSDCaddress, ethers.constants.MaxUint256, 0, 0, 0]
        },
      ];

      await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
    });

    it("should redeem max steakUSDC", async () => {
      const balance = await erc4626Contract.balanceOf(dsaWallet0.address);
      console.log("Share balance :>> ", balance.toString());

      // Returns max Shares
      const maxRedeem: BigNumber = await erc4626Contract.maxRedeem(dsaWallet0.address);
      console.log("maxRedeem :>> ", maxRedeem.toString());


      const beforeVaultbalance = await erc4626Contract.balanceOf(dsaWallet0.address);
      console.log("beforeVaultbalance :>> ", beforeVaultbalance.toString());

      let spells = [
        {
          connector: connectorName,
          method: "redeem",
          args: [steakUSDCaddress, ethers.constants.MaxUint256, 0, dsaWallet0.address, 0, 0]
        }
      ];

      let tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);

      const afterVaultbalance = await erc4626Contract.balanceOf(dsaWallet0.address);
      console.log("afterVaultbalance :>> ", afterVaultbalance.toString());
    });


    it("should deposit asset to bbETH", async () => {
      const assets = "1000000000000000000";

      const beforebalance = await bbETHContract.balanceOf(dsaWallet0.address);
      console.log("Share before balance :>> ", beforebalance.toString());

      let spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [bbETHaddress, assets, 0, 0, 0]
        },
      ];

      let tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
    });

    it("should redeem asset to bbETH", async () => {
      const balance = await bbETHContract.balanceOf(dsaWallet0.address);
      console.log("Share balance :>> ", balance.toString());

      // Returns max Shares
      const maxRedeem: BigNumber = await bbETHContract.maxRedeem(dsaWallet0.address);
      console.log("maxRedeem :>> ", maxRedeem.toString());


      const beforeVaultbalance = await bbETHContract.balanceOf(dsaWallet0.address);
      console.log("beforeVaultbalance :>> ", beforeVaultbalance.toString());

      let spells = [
        {
          connector: connectorName,
          method: "redeem",
          args: [bbETHaddress, ethers.utils.parseEther('0.5'), 0, dsaWallet0.address, 0, 0]
        }
      ];

      let tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);

      const afterVaultbalance = await bbETHContract.balanceOf(dsaWallet0.address);
      console.log("afterVaultbalance :>> ", afterVaultbalance.toString());
    });

    it("should deposit asset to bbETH with Max", async () => {

      const beforebalance = await bbETHContract.balanceOf(dsaWallet0.address);
      console.log("Share before balance :>> ", beforebalance.toString());

      let spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [bbETHaddress, ethers.constants.MaxUint256, 0, 0, 0]
        },
      ];

      let tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
    });

    it("should redeem asset to bbETH", async () => {
      const balance = await bbETHContract.balanceOf(dsaWallet0.address);
      console.log("Share balance :>> ", balance.toString());

      // Returns max Shares
      const maxRedeem: BigNumber = await bbETHContract.maxRedeem(dsaWallet0.address);
      console.log("maxRedeem :>> ", maxRedeem.toString());


      const beforeVaultbalance = await bbETHContract.balanceOf(dsaWallet0.address);
      console.log("beforeVaultbalance :>> ", beforeVaultbalance.toString());

      let spells = [
        {
          connector: connectorName,
          method: "redeem",
          args: [bbETHaddress, ethers.constants.MaxUint256, 0, dsaWallet0.address, 0, 0]
        }
      ];

      let tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);

      const afterVaultbalance = await bbETHContract.balanceOf(dsaWallet0.address);
      console.log("afterVaultbalance :>> ", afterVaultbalance.toString());
    });
  });
});
