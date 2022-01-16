import hre from "hardhat";
import { expect } from "chai";
const { ethers } = hre; //check
import { BigNumber } from "bignumber.js";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/polygon/addresses";
import { addLiquidity } from "../../../scripts/tests/addLiquidity";
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2UniswapV3AutoRouterPolygon__factory } from "../../../typechain";
import er20abi from "../../../scripts/constant/abi/basics/erc20.json";
import type { Signer, Contract } from "ethers";
import { CurrencyAmount, Token, TradeType, Currency, Percent } from "@uniswap/sdk-core";
import { AlphaRouter } from "@uniswap/smart-order-router";

describe("Auto Router", function () {
  const connectorName = "Auto-Router-test";

  let dsaWallet0: Contract;
  let wallet0: Signer, wallet1: Signer;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;

  // @ts-ignore
  const provider = new ethers.providers.JsonRpcProvider(hre.config.networks.hardhat.forking.url);
  const router = new AlphaRouter({ chainId: 137, provider });

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url
          }
        }
      ]
    });
    [wallet0, wallet1] = await ethers.getSigners();

    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2UniswapV3AutoRouterPolygon__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
    console.log("Connector address", connector.address);
  });

  it("Should have contracts deployed.", async function () {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
      dsaWallet0 = await buildDSAv2(await wallet0.getAddress());
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit Matic  into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
    });
  });

  describe("Main", function () {
    
    it("should swap the tokens ", async function () {
      const buyTokenAddress = "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063"; //dai
      const sellTokenAddress = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"; //matic
      const sellTokenDecimals = 18;
      const buyTokenDecimals = 18;
      const amount = 1;

      const wmaticAddr = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270";

      const srcAmount = new BigNumber(amount).times(new BigNumber(10).pow(sellTokenDecimals)).toFixed(0);
      const sellToken = new Token(137, wmaticAddr, sellTokenDecimals);
      const buyToken = new Token(137, buyTokenAddress, buyTokenDecimals);
      const sellAmount = CurrencyAmount.fromRawAmount(sellToken, srcAmount);

      const deadline = 1696000000 // Fri Sep 29 2023 15:06:40 GMT+0000
      const route = await router.route(sellAmount, buyToken, TradeType.EXACT_INPUT, {
        recipient: dsaWallet0.address,
        slippageTolerance: new Percent(5, 100),
        deadline
      });
    
      const calldata = route?.methodParameters?.calldata;
    
      const _buyAmount = route?.quote.toFixed();
      const buyTokenAmount = new BigNumber(String(_buyAmount)).times(new BigNumber(10).pow(buyTokenDecimals)).toFixed(0);
      
   
      function caculateUnitAmt(
        buyAmount: any,
        sellAmount: any,
        buyDecimal: any,
        sellDecimal: any,
        maxSlippage: any
      ) {
        let unitAmt: any;
        unitAmt = new BigNumber(buyAmount)
          .dividedBy(10 ** buyDecimal)
          .dividedBy(new BigNumber(sellAmount).dividedBy(10 ** sellDecimal));
        unitAmt = unitAmt.multipliedBy((100 - maxSlippage) / 100);
        unitAmt = unitAmt.multipliedBy(1e18).toFixed(0);
        return unitAmt;
      }

      const unitAmt = caculateUnitAmt(
        buyTokenAmount,
        srcAmount,
        buyTokenDecimals,
        sellTokenDecimals,
        1
      );

      const spells = [
        {
          connector: connectorName,
          method: "sell",
          args: [buyTokenAddress, sellTokenAddress, srcAmount, unitAmt, calldata, 0]
        }
      ];

      const buyTokenContract = await ethers.getContractAt(
        er20abi,
        buyTokenAddress,
      );

      const initialBuyTokenBalance = await buyTokenContract.balanceOf(dsaWallet0.address)

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), await wallet1.getAddress());
      const receipt = await tx.wait();

      const finalBuyTokenBalance = await buyTokenContract.balanceOf(dsaWallet0.address)

      
      expect(finalBuyTokenBalance).to.be.gt(initialBuyTokenBalance);
    });
   
  });
});
