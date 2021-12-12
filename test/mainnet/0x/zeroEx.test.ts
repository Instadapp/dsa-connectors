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
import { ConnectV2ZeroEx, ConnectV2ZeroEx__factory } from "../../../typechain";
import er20abi from "../../../scripts/constant/abi/basics/erc20.json";
import type { Signer, Contract } from "ethers";

describe("ZeroEx", function() {
  const connectorName = "zeroEx-test";

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
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
          },
        },
      ],
    });
    [wallet0, wallet1] = await ethers.getSigners();

    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(
      abis.core.connectorsV2,
      addresses.core.connectorsV2
    );
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2ZeroEx__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
    console.log("Connector address", connector.address);
  });

  it("Should have contracts deployed.", async function() {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function() {
    it("Should build DSA v2", async function() {
      dsaWallet0 = await buildDSAv2(await wallet0.getAddress());
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH into DSA wallet", async function() {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10"),
      });
      // console.log(dsaWallet0.address);
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
        /* Eth -> dai */
        const sellTokenAddress = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"; // eth,  decimals 18
        const sellTokenDecimals = 18;
        const buyTokenAddress = "0x6b175474e89094c44da98b954eedeac495271d0f"; // dai, decimals 18
        const buyTokenDecimals = 18;
        const amount = 1;

        const srcAmount = new BigNumber(amount)
          .times(new BigNumber(10).pow(sellTokenDecimals))
          .toFixed(0);

        const fromAddress = dsaWallet0.address;

        let url = `https://api.0x.org/swap/v1/quote`;

        const params = {
          buyToken: "DAI",
          sellToken: "ETH",
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
        .cast(...encodeSpells(spells), await wallet1.getAddress());
      const receipt = await tx.wait();

      const daiToken = await ethers.getContractAt(
        er20abi,
        "0x6b175474e89094c44da98b954eedeac495271d0f" // dai address
      );

      expect(await daiToken.balanceOf(dsaWallet0.address)).to.be.gte(
        buyTokenAmount
      );
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("9")
      );
    });
  });
});
