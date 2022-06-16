import hre from "hardhat";
import axios from "axios";
import { expect } from "chai";
const { ethers } = hre; //check
import { BigNumber } from "bignumber.js";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/polygon/addresses";
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2SwapAggregatorPolygon__factory } from "../../../typechain";
import er20abi from "../../../scripts/constant/abi/basics/erc20.json";
import type { Signer, Contract } from "ethers";

describe("Swap", function () {
  const connectorName = "swap-test";

  let dsaWallet0: Contract;
  let wallet0: Signer, wallet1: Signer;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;

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
      contractArtifact: ConnectV2SwapAggregatorPolygon__factory,
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
      console.log(dsaWallet0.address);
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit matic into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("50")
      });

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
    });
  });

  describe("Main", function () {
    it("should swap the tokens", async function () {
      let buyTokenAmountZeroX: any;
      let buyTokenAmount1Inch: any;
      let buyTokenAmountParaswap: any;
      let unitAmount1Inch: any;
      let calldata1Inch: any;

      async function getSelector(connector: string) {
        var abi = [
          "function swap(address,address,uint256,uint256,bytes,uint256)",
          "function sell(address,address,uint256,uint256,bytes,uint256)"
        ];
        var iface = new ethers.utils.Interface(abi);
        var id;
        if (connector == "1INCH-A") {
          id = iface.getSighash("sell");
        } else {
          id = iface.getSighash("swap");
        }

        return id;
      }

      async function getArg() {
        // const slippage = 0.5;
        /* matic -> usdt */
        const sellTokenAddress = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"; // matic,  decimals 18
        const sellTokenDecimals = 18;
        const buyTokenAddress = "0xc2132d05d31c914a87c6611c10748aeb04b58e8f"; // USDT, decimals 6
        const buyTokenDecimals = 6;
        const amount = 1;

        const srcAmount = new BigNumber(amount).times(new BigNumber(10).pow(sellTokenDecimals)).toFixed(0);

        let zeroXUrl = `https://polygon.api.0x.org/swap/v1/quote`;
        let paraswapUrl1 = `https://apiv5.paraswap.io/prices/`;
        let paraswapUrl2 = `https://apiv5.paraswap.io/transactions/137?ignoreChecks=true`;

        //zeroX
        const paramsZeroX = {
          buyToken: "USDT",
          sellToken: "MATIC",
          sellAmount: "1000000000000000000" // Always denominated in wei
        };

        const responseZeroX = await axios.get(zeroXUrl, { params: paramsZeroX }).then((data: any) => data);
        buyTokenAmountZeroX = responseZeroX.data.buyAmount;
        const calldataZeroX = responseZeroX.data.data;

        //paraswap
        let paramsPara = {
          srcToken: sellTokenAddress,
          destToken: buyTokenAddress,
          srcDecimals: sellTokenDecimals,
          destDecimals: buyTokenDecimals,
          amount: srcAmount,
          side: "SELL",
          network: 137
        };

        const priceRoute = (await axios.get(paraswapUrl1, { params: paramsPara })).data.priceRoute;
        buyTokenAmountParaswap = priceRoute.destAmount;
        let minAmount = new BigNumber(priceRoute.destAmount).times((100 - 1) / 100).toFixed(0);

        let txConfig = {
          priceRoute: priceRoute,
          srcToken: sellTokenAddress,
          destToken: buyTokenAddress,
          srcDecimals: sellTokenDecimals,
          destDecimals: buyTokenDecimals,
          srcAmount: srcAmount,
          destAmount: minAmount,
          userAddress: dsaWallet0.address
        };
        const calldataPara = (await axios.post(paraswapUrl2, txConfig)).data.data;

        let calculateUnitAmt = (buyAmount: any) => {
          const buyTokenAmountRes = new BigNumber(buyAmount)
            .dividedBy(new BigNumber(10).pow(buyTokenDecimals))
            .toFixed(8);

          let unitAmt: any = new BigNumber(buyTokenAmountRes).dividedBy(new BigNumber(amount));

          unitAmt = unitAmt.multipliedBy((100 - 1) / 100);
          unitAmt = unitAmt.multipliedBy(1e18).toFixed(0);
          return unitAmt;
        };
        let unitAmt0x = calculateUnitAmt(buyTokenAmountZeroX);
        let unitAmtParaswap = calculateUnitAmt(buyTokenAmountParaswap);

        function getCallData(connector: string, unitAmt: any, callData: any) {
          var abi = [
            "function swap(address,address,uint256,uint256,bytes,uint256)",
            "function sell(address,address,uint256,uint256,bytes,uint256)"
          ];
          var iface = new ethers.utils.Interface(abi);
          const spell = connector === "1INCH-A" ? "sell" : "swap";
          let data = iface.encodeFunctionData(spell, [buyTokenAddress, sellTokenAddress, srcAmount, unitAmt, callData, 0]);
          return data;
        }
        let dataPara = ethers.utils.hexlify(await getCallData("PARASWAP-A", unitAmtParaswap, calldataPara));
        let dataZeroX = ethers.utils.hexlify(await getCallData("ZEROX-A", unitAmt0x, calldataZeroX));
        let datas = [dataZeroX, dataPara];

        let connectors = ["ZEROX-A", "PARASWAP-A"];

        return [connectors, datas];
      }

      let arg = await getArg();
      const spells = [
        {
          connector: connectorName,
          method: "swap",
          args: arg
        }
      ];
      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), await wallet1.getAddress());
      const receipt = await tx.wait();

      const usdtToken = await ethers.getContractAt(
        er20abi,
        "0xc2132d05d31c914a87c6611c10748aeb04b58e8f" // usdt address
      );

      expect(await usdtToken.balanceOf(dsaWallet0.address)).to.be.gte(buyTokenAmountZeroX);
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(ethers.utils.parseEther("9"));
    });
  });
});
