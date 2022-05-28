import { expect } from "chai";
import hre from "hardhat";
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle;

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addLiquidity } from "../../../scripts/tests/addLiquidity";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";
import type { Signer, Contract } from "ethers";

import { abi } from "@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json";
import { ConnectV2UniswapV3Swap__factory } from "../../../typechain";

const FeeAmount = {
  LOW: 500,
  MEDIUM: 3000,
  HIGH: 10000
};

const TICK_SPACINGS: Record<number, number> = {
  500: 10,
  3000: 60,
  10000: 200
};

const USDT_ADDR = "0xdac17f958d2ee523a2206206994597c13d831ec7";
const DAI_ADDR = "0x6b175474e89094c44da98b954eedeac495271d0f";

let tokenIds: any[] = [];
let liquidities: any[] = [];
const abiCoder = ethers.utils.defaultAbiCoder;

describe("UniswapV3 [Mainnet]", function () {
  const connectorName = "UniswapV3-Swap-v1";

  let dsaWallet0: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;
  let nftManager: Contract;

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
            blockNumber: 14674358
          }
        }
      ]
    });
    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    nftManager = await ethers.getContractAt(abi, "0xC36442b4a4522E871399CD717aBDD847Ab11FE88");
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2UniswapV3Swap__factory,
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
      dsaWallet0 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH & DAI into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));

      await addLiquidity("dai", dsaWallet0.address, ethers.utils.parseEther("100000"));
    });

    it("Deposit ETH & USDT into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));

      await addLiquidity("usdt", dsaWallet0.address, ethers.utils.parseEther("100000"));
    });
  });

  describe("Main", function () {
    it("Should buy successfully", async function () {
      const ethAmount = ethers.utils.parseEther("0.1");
      const unitAmt = ethers.utils.parseEther("2994.474881115");
      const ethAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";
      const getId = "0";
      const setId = "0";

      const spells = [
        {
          connector: connectorName,
          method: "buy",
          args: [ethAddress, DAI_ADDR, FeeAmount.MEDIUM, unitAmt, ethAmount, getId, setId]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      // console.log(receipt);
    });

    it("Should sell successfully", async function () {
      const ethAmount = ethers.utils.parseEther("0.1");
      const unitAmt = ethers.utils.parseEther("2693.010801400");
      const ethAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";
      const getId = "0";
      const setId = "0";

      const spells = [
        {
          connector: connectorName,
          method: "sell",
          args: [DAI_ADDR, ethAddress, FeeAmount.MEDIUM, unitAmt, ethAmount, getId, setId]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      // console.log(receipt);
    });
  });
});

const getMinTick = (tickSpacing: number) => Math.ceil(-887272 / tickSpacing) * tickSpacing;
const getMaxTick = (tickSpacing: number) => Math.floor(887272 / tickSpacing) * tickSpacing;
