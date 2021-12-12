import hre from "hardhat";
import axios from "axios";
import { expect } from "chai";
const { ethers } = hre; //check
import { BigNumber } from "bignumber.js";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2ZeroExPolygon, ConnectV2ZeroExPolygon__factory } from "../../../typechain";
import er20abi from "../../../scripts/constant/abi/basics/erc20.json";
import type { Signer, Contract } from "ethers";

describe("ZeroEx", function() {
  const connectorName = "zeroEx-test";

  let dsaWallet0: Contract;
  let wallet0: Signer, wallet1: Signer;
  let masterSigner: Signer;
  let instaConnectorsV2: any;
  let connector: any;

  before(async () => {
    //   await hre.network.provider.request({
    //     method: "hardhat_reset",
    //     params: [
    //       {
    //         forking: {
    //           // @ts-ignore
    //           jsonRpcUrl: hre.config.networks.forking.url,
    //           blockNumber: 13300000,
    //         },
    //       },
    //     ],
    // });
    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(
      abis.core.connectorsV2,
      addresses.core.connectorsV2
    );
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2ZeroExPolygon__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
    console.log("Connector address", connector.address);
  });

  it("Should have contracts deployed.", async function() {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!masterSigner.getAddress()).to.be.true;
  });

  describe("DSA wallet setup", function() {
    it("Should build DSA v2", async function() {
      dsaWallet0 = await buildDSAv2(wallet0.getAddress());
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit matic into DSA wallet", async function() {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10"),
      });

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseEther("10")
      );
    });
  });

  describe("Main", function() {
    it("should swap the tokens", async function() {
      let buyTokenAmount: any;
      async function getArg() {
        // const slippage = 0.5;

        /* matic -> dai */
        const sellTokenAddress = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"; // matic,  decimals 18
        const sellTokenDecimals = 18;
        const buyTokenAddress = "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063"; // dai, decimals 18
        const buyTokenDecimals = 18;
        const amount = 1;

        const srcAmount = new BigNumber(amount)
          .times(new BigNumber(10).pow(sellTokenDecimals))
          .toFixed(0);

        const fromAddress = dsaWallet0.address;

        let url = `https://polygon.api.0x.org/swap/v1/quote`;

        const params = {
          buyToken: "DAI",
          sellToken: "MATIC",
          sellAmount: "1000000000000000000", // Always denominated in wei
        };

        const response = await axios
          .get(url, { params: params })
          .then((data: any) => data);

        buyTokenAmount = response.data.buyAmount;
        const calldata = response.data.data;

        let caculateUnitAmt = () => {
          const buyTokenAmountRes = new BigNumber(buyTokenAmount)
            .dividedBy(new BigNumber(10).pow(buyTokenDecimals))
            .toFixed(8);

          let unitAmt: any = new BigNumber(buyTokenAmountRes).dividedBy(
            new BigNumber(amount)
          );

          unitAmt = unitAmt.multipliedBy((100 - 0.3) / 100);
          unitAmt = unitAmt.multipliedBy(1e18).toFixed(0);
          return unitAmt;
        };
        let unitAmt = caculateUnitAmt();


        return [
          buyTokenAddress,
          sellTokenAddress,
          srcAmount,
          unitAmt,
          calldata,
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
        .cast(...encodeSpells(spells), wallet1.getAddress());
      const receipt = await tx.wait();
    

      const idai = await ethers.getContractAt(
        er20abi,
        "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063" // dai address
      );

        expect(await idai.balanceOf(dsaWallet0.address)).to.be.gte(
          buyTokenAmount
        );
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("9")
      );
    });
  });
});
