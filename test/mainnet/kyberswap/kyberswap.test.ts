import hre from "hardhat";
import { expect } from "chai";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import {
  ConnectV2KyberAggregator__factory,
} from "../../../typechain"
import { parseEther } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { tokens } from "../../../scripts/tests/mainnet/tokens";
import { constants } from "../../../scripts/constant/constant";
import { addLiquidity } from "../../../scripts/tests/addLiquidity";
import BigNumber from "bignumber.js";
import axios from "axios";
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle;
describe("Kyberswap", function() {
  const connectorName = "kyberswap-test";
  let dsaWallet0: any;
  let masterSigner: any;
  let instaConnectorsV2: any;
  let connector: any;
  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;
  before(async () => {
    await hre.network.provider.request({
        method: "hardhat_reset",
        params: [
            {
                forking: {
                  // @ts-ignore
                    jsonRpcUrl: hre.config.networks.hardhat.forking.url,
                    // blockNumber: 13300000,
                },
            },
        ],
    });
    masterSigner = await getMasterSigner();
    const erc20 = abis.basic.erc20;
    instaConnectorsV2 = await ethers.getContractAt(
      abis.core.connectorsV2,
      addresses.core.connectorsV2
    );

    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2KyberAggregator__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
    // console.log("Connector address", connector.address);
  });
  it("Should have contracts deployed.", async function() {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!masterSigner.address).to.be.true;
  });
  describe("DSA wallet setup", function() {
    it("Should build DSA v2", async function() {
      dsaWallet0 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet0.address).to.be.true;
    });
    it("Deposit ETH into DSA wallet", async function() {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10"),
      });

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseEther("10")
      );
    });
  });
  describe("Main", async function() {
    it("should swap successfully", async function() {
      const latestBlock = await hre.ethers.provider.getBlock("latest");
      console.log('latestBlock: ', latestBlock.number)
      async function getArg() {
        const slippage = 1;
        /* eth -> USDT */
        const sellTokenAddress = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"; // eth,  decimals 18
        const sellTokenDecimals = 18;
        const buyTokenAddress = "0xdac17f958d2ee523a2206206994597c13d831ec7"; // USDT, decimals 6
        const buyTokenDecimals = 6;
        const amount = 2;
        const srcAmount = new BigNumber(amount)
          .times(new BigNumber(10).pow(sellTokenDecimals))
          .toFixed(0);
        const fromAddress = dsaWallet0.address;
        let url = `https://aggregator-api.kyberswap.com/ethereum/api/v1/routes`;
        let params = {
          tokenIn: sellTokenAddress,
          tokenOut: buyTokenAddress,
          amountIn: srcAmount,
        };

        const routeSummary = await axios
          .get(url, { params: params })
          .then((response) => response.data.data.routeSummary);

        let txConfig = {
          routeSummary: routeSummary,
          sender: fromAddress,
          recipient: fromAddress,
        };

        let url2 = "https://aggregator-api.kyberswap.com/ethereum/api/v1/route/build";
        const calldata = await axios
          .post(url2, txConfig)
          .then((response) => response.data.data);

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

        let unitAmt = caculateUnitAmt(
          routeSummary.amountOut,
          srcAmount,
          buyTokenDecimals,
          sellTokenDecimals,
          1
        );
        console.log('unitAmt: ', unitAmt.toString())
        return [
          buyTokenAddress,
          sellTokenAddress,
          srcAmount,
          unitAmt,
          calldata.data,
          0,
        ];
      }
      
      let arg = await getArg();

      const spells = [
        {
          connector: connectorName,
          method: "swap",
          args: arg,
        },
      ];
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("8")
      );
    });
  });
});
