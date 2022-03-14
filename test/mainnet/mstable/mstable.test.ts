import { expect } from "chai";
import hre from "hardhat";
const { waffle, ethers } = hre;
const { provider } = waffle;

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";

import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";
import type { Signer, Contract } from "ethers";

import { ConnectV2mStable__factory, IERC20Minimal__factory, IERC20Minimal } from "../../../typechain";

import { executeAndAssertDeposit, executeAndAssertSwap, executeAndAssertWithdraw } from "./mstable.utils";

import {
  fundWallet,
  getToken,
  simpleToExactAmount,
  DEAD_ADDRESS,
  calcMinOut,
  ONE_DAY,
  increaseTime,
  connectorName,
  toEther
} from "./mstable.helpers";

describe("MStable", async () => {
  let dsaWallet0: Contract;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;

  let mtaToken: IERC20Minimal = IERC20Minimal__factory.connect(getToken("MTA").tokenAddress, provider);
  let mUsdToken: IERC20Minimal = IERC20Minimal__factory.connect(getToken("mUSD").tokenAddress, provider);
  let imUsdToken: IERC20Minimal = IERC20Minimal__factory.connect(getToken("imUSD").tokenAddress, provider);
  let imUsdVault: IERC20Minimal = IERC20Minimal__factory.connect(getToken("imUSDVault").tokenAddress, provider);

  let daiToken: IERC20Minimal = IERC20Minimal__factory.connect(getToken("DAI").tokenAddress, provider);
  let usdcToken: IERC20Minimal = IERC20Minimal__factory.connect(getToken("USDC").tokenAddress, provider);
  let alusdToken: IERC20Minimal = IERC20Minimal__factory.connect(getToken("alUSD").tokenAddress, provider);

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;

  describe("DSA wallet", async () => {
    const fundAmount = simpleToExactAmount(10000);

    const setup = async () => {
      await hre.network.provider.request({
        method: "hardhat_reset",
        params: [
          {
            forking: {
              // @ts-ignore
              jsonRpcUrl: hre.config.networks.hardhat.forking.url,
              blockNumber: 13905885
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

      dsaWallet0 = await buildDSAv2(wallet0.address);

      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: simpleToExactAmount(10)
      });

      await fundWallet("mUSD", fundAmount, dsaWallet0.address);
      await fundWallet("DAI", fundAmount, dsaWallet0.address);
      await fundWallet("alUSD", fundAmount, dsaWallet0.address);
    };

    describe("Deploy", async () => {
      before(async () => {
        await setup();
      });

      it("Should deploy properly", async () => {
        expect(instaConnectorsV2.address).to.be.properAddress;
        expect(connector.address).to.be.properAddress;
        expect(await masterSigner.getAddress()).to.be.properAddress;

        expect(dsaWallet0.address).to.be.properAddress;
      });
      it("Should fund the wallet", async () => {
        expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));

        expect(await mUsdToken.balanceOf(dsaWallet0.address)).to.be.gte(fundAmount);
        expect(await daiToken.balanceOf(dsaWallet0.address)).to.be.gte(fundAmount);
        expect(await alusdToken.balanceOf(dsaWallet0.address)).to.be.gte(fundAmount);
      });
      it("Should not have vault tokens prior", async () => {
        // No deposits prior
        expect(await imUsdToken.balanceOf(dsaWallet0.address)).to.be.eq(0);
        expect(await imUsdVault.balanceOf(dsaWallet0.address)).to.be.eq(0);
      });
    });

    describe("Main SAVE", async () => {
      before(async () => {
        await setup();
      });
      it("Should deposit mUSD to Vault successfully", async () => {
        const depositAmount = simpleToExactAmount(100);
        const minOut = depositAmount;

        await executeAndAssertDeposit("deposit", mUsdToken, depositAmount, dsaWallet0, wallet0, [minOut, true]);
      });
      it("Should deposit DAI to Vault successfully (mUSD bAsset)", async () => {
        const depositAmount = simpleToExactAmount(100);
        const minOut = calcMinOut(depositAmount, 0.02);

        await executeAndAssertDeposit("deposit", daiToken, depositAmount, dsaWallet0, wallet0, [minOut, true]);
      });
      it("Should deposit alUSD to Vault successfully (via Feeder Pool)", async () => {
        const depositAmount = simpleToExactAmount(100);
        const minOut = calcMinOut(depositAmount, 0.02);
        const path = getToken("alUSD").feederPool;

        await executeAndAssertDeposit("depositViaSwap", alusdToken, depositAmount, dsaWallet0, wallet0, [
          minOut,
          path,
          true
        ]);
      });
      it("Should withdraw from Vault to mUSD", async () => {
        const withdrawAmount = simpleToExactAmount(100);
        const minOut = simpleToExactAmount(1);

        await executeAndAssertWithdraw("withdraw", mUsdToken, withdrawAmount, dsaWallet0, wallet0, [minOut, true]);
      });
      it("Should withdraw from Vault to DAI (mUSD bAsset)", async () => {
        const withdrawAmount = simpleToExactAmount(100);
        const minOut = simpleToExactAmount(1);

        await executeAndAssertWithdraw("withdraw", mUsdToken, withdrawAmount, dsaWallet0, wallet0, [minOut, true]);
      });
      it("Should withdraw from Vault to alUSD (via Feeder Pool)", async () => {
        const withdrawAmount = simpleToExactAmount(100);
        const minOut = simpleToExactAmount(1);
        const path = getToken("alUSD").feederPool;

        await executeAndAssertWithdraw("withdrawViaSwap", alusdToken, withdrawAmount, dsaWallet0, wallet0, [
          minOut,
          path,
          true
        ]);
      });
      it("Should claim Rewards", async () => {
        const mtaBalanceBefore = await mtaToken.balanceOf(dsaWallet0.address);
        console.log("MTA balance before: ", toEther(mtaBalanceBefore));

        // Wait a bit and let the rewards accumulate
        await increaseTime(ONE_DAY);

        const spells = [
          {
            connector: connectorName,
            method: "claimRewards",
            args: [0, 0]
          }
        ];

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), DEAD_ADDRESS);

        const mtaBalanceAfter = await mtaToken.balanceOf(dsaWallet0.address);
        console.log("MTA balance after: ", toEther(mtaBalanceAfter));

        expect(mtaBalanceAfter).to.be.gt(mtaBalanceBefore);
      });
    });
    describe("Main SWAP", async () => {
      before(async () => {
        await setup();
      });
      it("Should swap mUSD to bAsset (redeem)", async () => {
        const swapAmount = simpleToExactAmount(100);
        await executeAndAssertSwap("swap", mUsdToken, 18, daiToken, 18, swapAmount, dsaWallet0, wallet0);
      });
      it("Should swap mUSD to fAsset (via feeder pool)", async () => {
        const swapAmount = simpleToExactAmount(100);
        const path = getToken("alUSD").feederPool;
        await executeAndAssertSwap("swapViaFeeder", mUsdToken, 18, alusdToken, 18, swapAmount, dsaWallet0, wallet0, [
          path
        ]);
      });
      it("Should swap bAsset to mUSD (mint)", async () => {
        const swapAmount = simpleToExactAmount(100);
        await executeAndAssertSwap("swap", daiToken, 18, mUsdToken, 18, swapAmount, dsaWallet0, wallet0);
      });
      it("Should swap bAsset to bAsset (swap)", async () => {
        const swapAmount = simpleToExactAmount(100);
        await executeAndAssertSwap("swap", daiToken, 18, usdcToken, 6, swapAmount, dsaWallet0, wallet0);
      });
      it("Should swap bAsset to fAsset (via feeder)", async () => {
        const swapAmount = simpleToExactAmount(100);
        const path = getToken("alUSD").feederPool;
        await executeAndAssertSwap("swapViaFeeder", daiToken, 18, alusdToken, 18, swapAmount, dsaWallet0, wallet0, [
          path
        ]);
      });
      it("Should swap fAsset to bAsset (via feeder)", async () => {
        const swapAmount = simpleToExactAmount(100);
        const path = getToken("alUSD").feederPool;
        await executeAndAssertSwap("swapViaFeeder", alusdToken, 18, daiToken, 18, swapAmount, dsaWallet0, wallet0, [
          path
        ]);
      });
      it("Should swap fAsset to mUSD (via feeder)", async () => {
        const swapAmount = simpleToExactAmount(100);
        const path = getToken("alUSD").feederPool;
        await executeAndAssertSwap("swapViaFeeder", alusdToken, 18, mUsdToken, 18, swapAmount, dsaWallet0, wallet0, [
          path
        ]);
      });
    });
  });
});
