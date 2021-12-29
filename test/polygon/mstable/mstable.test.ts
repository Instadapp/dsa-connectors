import { expect } from "chai";
import hre from "hardhat";
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle;

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addLiquidity } from "../../../scripts/tests/addLiquidity";

import { addresses } from "../../../scripts/tests/polygon/addresses";
import { abis } from "../../../scripts/constant/abis";
import { tokens } from "../../../scripts/tests/polygon/tokens";
import type { Signer, Contract, BigNumber } from "ethers";

import { ConnectV2mStable__factory, IERC20Minimal__factory, IERC20Minimal } from "../../../typechain";

import { fundWallet, getToken, simpleToExactAmount, DEAD_ADDRESS, calcMinOut } from "./mstable.helpers";

describe("MStable", async () => {
  const connectorName = "MStable";

  let dsaWallet0: Contract;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;

  let mUsdToken: IERC20Minimal = IERC20Minimal__factory.connect(getToken("mUSD").tokenAddress, provider);
  let daiToken: IERC20Minimal = IERC20Minimal__factory.connect(getToken("DAI").tokenAddress, provider);
  let fraxToken: IERC20Minimal = IERC20Minimal__factory.connect(getToken("FRAX").tokenAddress, provider);
  let imUsdToken: IERC20Minimal = IERC20Minimal__factory.connect(getToken("imUSD").tokenAddress, provider);
  let imUsdVault: IERC20Minimal = IERC20Minimal__factory.connect(getToken("imUSDVault").tokenAddress, provider);

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;

  const toEther = (amount: BigNumber) => ethers.utils.formatEther(amount);

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 23059414
          }
        }
      ]
    });

    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2mStable__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });

    console.log("Connector address", connector.address);
  });
  it("should deploy", async () => {
    expect(instaConnectorsV2.address).to.be.properAddress;
    expect(connector.address).to.be.properAddress;
    expect(await masterSigner.getAddress()).to.be.properAddress;
  });
  describe("DSA wallet", async () => {
    it("Should build DSA v2", async () => {
      dsaWallet0 = await buildDSAv2(wallet0.address);
      expect(dsaWallet0.address).to.be.properAddress;
    });
    it("Deposit ETH and tokens into DSA Wallet", async () => {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: simpleToExactAmount(10)
      });

      const fundAmount = simpleToExactAmount(10000);

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));

      await fundWallet("mUSD", fundAmount, dsaWallet0.address);
      await fundWallet("DAI", fundAmount, dsaWallet0.address);
      await fundWallet("FRAX", fundAmount, dsaWallet0.address);

      expect(await mUsdToken.balanceOf(dsaWallet0.address)).to.be.gte(fundAmount);
      expect(await daiToken.balanceOf(dsaWallet0.address)).to.be.gte(fundAmount);
      expect(await fraxToken.balanceOf(dsaWallet0.address)).to.be.gte(fundAmount);

      // No deposits prior
      expect(await imUsdToken.balanceOf(dsaWallet0.address)).to.be.eq(0);
      expect(await imUsdVault.balanceOf(dsaWallet0.address)).to.be.eq(0);
    });

    describe("Main", async () => {
      it("Should deposit mUSD to Vault successfully", async () => {
        const depositAmount = simpleToExactAmount(100);

        console.log(dsaWallet0.address);

        const mUsdBalanceBefore = await mUsdToken.balanceOf(dsaWallet0.address);
        console.log("mUSD balance before: ", toEther(mUsdBalanceBefore));

        const imUsdVaultBalanceBefore = await imUsdVault.balanceOf(dsaWallet0.address);
        console.log("imUSD Vault balance before: ", toEther(imUsdVaultBalanceBefore));

        const spells = [
          {
            connector: connectorName,
            method: "deposit",
            args: [mUsdToken.address, depositAmount]
          }
        ];

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), DEAD_ADDRESS);

        const mUsdBalanceAfter = await mUsdToken.balanceOf(dsaWallet0.address);
        console.log("mUSD balance after: ", toEther(mUsdBalanceAfter));

        const imUsdBalance = await imUsdToken.balanceOf(dsaWallet0.address);
        console.log("imUSD balance: ", toEther(imUsdBalance));

        const imUsdVaultBalance = await imUsdVault.balanceOf(dsaWallet0.address);
        console.log("imUSD Vault balance: ", toEther(imUsdVaultBalance));

        // Should have something in the vault but no imUSD
        expect(await imUsdToken.balanceOf(dsaWallet0.address)).to.be.eq(0);
        expect(await imUsdVault.balanceOf(dsaWallet0.address)).to.be.gt(0);
        expect(mUsdBalanceAfter).to.eq(mUsdBalanceBefore.sub(depositAmount));
      });
      it("Should deposit DAI to Vault successfully (mUSD bAsset)", async () => {
        const depositAmount = simpleToExactAmount(100);
        const minOut = calcMinOut(depositAmount, 0.02);

        const daiBalanceBefore = await daiToken.balanceOf(dsaWallet0.address);
        console.log("DAI balance before: ", toEther(daiBalanceBefore));
        const spells = [
          {
            connector: connectorName,
            method: "deposit",
            args: [daiToken.address, depositAmount, minOut]
          }
        ];
        const imUsdVaultBalanceBefore = await imUsdVault.balanceOf(dsaWallet0.address);
        console.log("imUSD Vault balance before: ", toEther(imUsdVaultBalanceBefore));

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), DEAD_ADDRESS);

        const daiBalanceAfter = await daiToken.balanceOf(dsaWallet0.address);
        console.log("DAI balance after: ", toEther(daiBalanceAfter));

        const imUsdVaultBalanceAfter = await imUsdVault.balanceOf(dsaWallet0.address);
        console.log("imUSD Vault balance after: ", toEther(imUsdVaultBalanceAfter));

        expect(imUsdVaultBalanceAfter).to.be.gt(imUsdVaultBalanceBefore);
        expect(await imUsdToken.balanceOf(dsaWallet0.address)).to.be.eq(0);
        expect(daiBalanceAfter).to.eq(daiBalanceBefore.sub(depositAmount));
      });
      it.skip("Should deposit FRAX to Vault successfully (via Feeder Pool)", async () => {
        const depositAmount = simpleToExactAmount(100);
        const minOut = calcMinOut(depositAmount, 0.02);

        const fraxBalanceBefore = await fraxToken.balanceOf(dsaWallet0.address);
        console.log("FRAX balance before: ", toEther(fraxBalanceBefore));

        const spells = [
          {
            connector: connectorName,
            method: "deposit",
            args: [fraxToken.address, depositAmount, minOut, getToken("FRAX").feederPool]
          }
        ];

        const imUsdVaultBalanceBefore = await imUsdVault.balanceOf(dsaWallet0.address);
        console.log("imUSD Vault balance before: ", toEther(imUsdVaultBalanceBefore));

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), DEAD_ADDRESS);

        const fraxBalanceAfter = await fraxToken.balanceOf(dsaWallet0.address);
        console.log("FRAX balance after: ", toEther(fraxBalanceAfter));

        const imUsdVaultBalanceAfter = await imUsdVault.balanceOf(dsaWallet0.address);
        console.log("imUSD Vault balance after: ", toEther(imUsdVaultBalanceAfter));

        expect(imUsdVaultBalanceAfter).to.be.gt(imUsdVaultBalanceBefore);
        expect(await imUsdToken.balanceOf(dsaWallet0.address)).to.be.eq(0);
        expect(fraxBalanceAfter).to.eq(fraxBalanceBefore.sub(depositAmount));
      });
      it.skip("Should withdraw from Vault to mUSD", async () => {});
      it.skip("Should withdraw from Vault to DAI (mUSD bAsset)", async () => {});
      it.skip("Should withdraw from Vault to FRAX (via Feeder Pool)", async () => {});
    });
  });
});
