import { expect, should } from "chai";
import hre, { ethers, waffle } from "hardhat";
import type { Signer, Contract } from "ethers";
import { ecsign, ecrecover, pubToAddress } from "ethereumjs-util";
import { keccak256 } from "@ethersproject/keccak256";
import { defaultAbiCoder } from "@ethersproject/abi";
import { BigNumber } from "bignumber.js";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { addresses } from "../../../scripts/tests/arbitrum/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { abis } from "../../../scripts/constant/abis";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { parseEther, parseUnits } from "ethers/lib/utils";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import encodeFlashcastData from "../../../scripts/tests/encodeFlashcastData";
import { ConnectV2AaveV3Arbitrum__factory, IERC20__factory } from "../../../typechain";

const ABI = ["function balanceOf(address account) public view returns (uint256)"];

const aDaiAddress = "0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE";
const aaveAddress = "0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654";
let account = "0xc5ed2333f8a2c351fca35e5ebadb2a82f5d254c3";
const DAI = "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1";
const USDC = "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8";
const mnemonic = "test test test test test test test test test test test junk";
const connectorName = "AAVE-V3-X";
let signer: any, wallet0: any;

const aaveAbi = [
  {
    inputs: [
      { internalType: "address", name: "asset", type: "address" },
      { internalType: "address", name: "user", type: "address" }
    ],
    name: "getUserReserveData",
    outputs: [
      { internalType: "uint256", name: "currentATokenBalance", type: "uint256" },
      { internalType: "uint256", name: "currentStableDebt", type: "uint256" },
      { internalType: "uint256", name: "currentVariableDebt", type: "uint256" },
      { internalType: "uint256", name: "principalStableDebt", type: "uint256" },
      { internalType: "uint256", name: "scaledVariableDebt", type: "uint256" },
      { internalType: "uint256", name: "stableBorrowRate", type: "uint256" },
      { internalType: "uint256", name: "liquidityRate", type: "uint256" },
      { internalType: "uint40", name: "stableRateLastUpdated", type: "uint40" },
      { internalType: "bool", name: "usageAsCollateralEnabled", type: "bool" }
    ],
    stateMutability: "view",
    type: "function"
  }
];

const erc20Abi = [
  {
    constant: false,
    inputs: [
      {
        name: "_spender",
        type: "address"
      },
      {
        name: "_value",
        type: "uint256"
      }
    ],
    name: "approve",
    outputs: [
      {
        name: "",
        type: "bool"
      }
    ],
    payable: false,
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    constant: true,
    inputs: [],
    name: "totalSupply",
    outputs: [
      {
        name: "",
        type: "uint256"
      }
    ],
    payable: false,
    stateMutability: "view",
    type: "function"
  },
  {
    constant: true,
    inputs: [
      {
        name: "_owner",
        type: "address"
      }
    ],
    name: "balanceOf",
    outputs: [
      {
        name: "balance",
        type: "uint256"
      }
    ],
    payable: false,
    stateMutability: "view",
    type: "function"
  },
  {
    constant: false,
    inputs: [
      {
        name: "_to",
        type: "address"
      },
      {
        name: "_value",
        type: "uint256"
      }
    ],
    name: "transfer",
    outputs: [
      {
        name: "",
        type: "bool"
      }
    ],
    payable: false,
    stateMutability: "nonpayable",
    type: "function"
  }
];

const token = new ethers.Contract(DAI, erc20Abi);
const aDai = new ethers.Contract(aDaiAddress, ABI);
const usdcToken = new ethers.Contract(USDC, erc20Abi);
const aave = new ethers.Contract(aaveAddress, aaveAbi);

describe("Aave v3 Position for Arbitrum", function () {
  let dsaWallet0: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;

  const wallet = ethers.Wallet.fromMnemonic(mnemonic);

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            //@ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 9333600
          }
        }
      ]
    });
    masterSigner = await getMasterSigner();
    [wallet0] = await ethers.getSigners();
    await hre.network.provider.send("hardhat_setBalance", [account, ethers.utils.parseEther("10").toHexString()]);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [account]
    });

    signer = await ethers.getSigner(account);

    await token.connect(signer).transfer(wallet0.address, ethers.utils.parseEther("10"));

    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2AaveV3Arbitrum__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
  });

  describe("Deployment", async () => {
    it("Should set correct name", async () => {
      expect(await connector.name()).to.eq("AaveV3-v1.2");
    });
  });

  describe("DSA wallet setup", async () => {
    it("Should build DSA v2", async () => {
      dsaWallet0 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("5")
      });

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("5"));
    });
  });

  describe("check user AAVE position", async () => {
    it("Should create DSA Aave v3 position of DAI(collateral) and USDC(debt)", async () => {
      await token.connect(signer).transfer(dsaWallet0.address, ethers.utils.parseEther("10"));

      const spells = [
        //deposit DAI in aave
        {
          connector: connectorName,
          method: "deposit",
          args: [DAI, parseEther("10"), 0, 0]
        },
        //borrow USDC from aave
        {
          connector: connectorName,
          method: "borrow",
          args: [USDC, parseUnits("3", 6), 2, 0, 0]
        }
      ];
      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
      const receipt = await tx.wait();
    });

    it("Should check position of dsa", async () => {
      expect(await aDai.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.gte(
        new BigNumber(10).multipliedBy(1e18).toString()
      );

      expect(await usdcToken.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.gte(
        new BigNumber(3).multipliedBy(1e6).toString()
      );

      expect((await aave.connect(wallet0).getUserReserveData(USDC, dsaWallet0.address)).currentStableDebt).to.be.equal(
        0
      );
      expect((await aave.connect(wallet0).getUserReserveData(USDC, dsaWallet0.address)).currentVariableDebt).to.be.gte(
        new BigNumber(3).multipliedBy(1e6).toString()
      );
      console.log(
        `\tstable borrow before: ${
          (await aave.connect(wallet0).getUserReserveData(USDC, dsaWallet0.address)).currentStableDebt
        }`
      );
      console.log(
        `\tvariable borrow before: ${
          (await aave.connect(wallet0).getUserReserveData(USDC, dsaWallet0.address)).currentVariableDebt
        }`
      );
    });

    it("Should swap borrowRateMode", async () => {
      const spells = [
        //deposit DAI in aave
        {
          connector: connectorName,
          method: "swapBorrowRateMode",
          args: [USDC, 2]
        }
      ];
      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
      const receipt = await tx.wait();
    });

    it("Should check position of dsa", async () => {
      expect(await aDai.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.gte(
        new BigNumber(10).multipliedBy(1e18).toString()
      );

      expect(await usdcToken.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.gte(
        new BigNumber(3).multipliedBy(1e6).toString()
      );
      expect(
        (await aave.connect(wallet0).getUserReserveData(USDC, dsaWallet0.address)).currentVariableDebt
      ).to.be.equal(0);
      expect((await aave.connect(wallet0).getUserReserveData(USDC, dsaWallet0.address)).currentStableDebt).to.be.gte(
        new BigNumber(3).multipliedBy(1e6).toString()
      );
      console.log(
        `\tstable borrow after: ${
          (await aave.connect(wallet0).getUserReserveData(USDC, dsaWallet0.address)).currentStableDebt
        }`
      );
      console.log(
        `\tvariable borrow after: ${
          (await aave.connect(wallet0).getUserReserveData(USDC, dsaWallet0.address)).currentVariableDebt
        }`
      );
    });
  });
});
