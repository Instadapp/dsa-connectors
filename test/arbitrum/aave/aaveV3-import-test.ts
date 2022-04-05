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
import { ConnectV2AaveV3ImportPermitArbitrum__factory, IERC20__factory } from "../../../typechain";

const ABI = [
  "function DOMAIN_SEPARATOR() public view returns (bytes32)",
  "function balanceOf(address account) public view returns (uint256)",
  "function nonces(address owner) public view returns (uint256)"
];

const aDaiAddress = "0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE"; 
const aaveAddress = "0x794a61358D6845594F94dc1DB02A252b5b4814aD";
let account = "0xc5ed2333f8a2c351fca35e5ebadb2a82f5d254c3";
const DAI = "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1";
const USDC = "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8";
const mnemonic = "test test test test test test test test test test test junk";
const connectorName = "AAVE-V3-IMPORT-PERMIT-X";
let signer: any, wallet0: any;

const aaveAbi = [
  {
    inputs: [
      { internalType: "address", name: "asset", type: "address" },
      { internalType: "uint256", name: "amount", type: "uint256" },
      { internalType: "uint256", name: "interestRateMode", type: "uint256" },
      { internalType: "uint16", name: "referralCode", type: "uint16" },
      { internalType: "address", name: "onBehalfOf", type: "address" }
    ],
    name: "borrow",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "asset", type: "address" },
      { internalType: "uint256", name: "amount", type: "uint256" },
      { internalType: "address", name: "onBehalfOf", type: "address" },
      { internalType: "uint16", name: "referralCode", type: "uint16" }
    ],
    name: "supply",
    outputs: [],
    stateMutability: "nonpayable",
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

describe("Import Aave v3 Position for Arbitrum", function () {
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
      contractArtifact: ConnectV2AaveV3ImportPermitArbitrum__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
  });

  describe("check user AAVE position", async () => {
    it("Should create Aave v3 position of DAI(collateral) and USDC(debt)", async () => {
      // approve DAI to aavePool
      await token.connect(wallet0).approve(aaveAddress, parseEther("10"));

      //deposit DAI in aave
      await aave.connect(wallet0).supply(DAI, parseEther("10"), wallet.address, 3228);
      console.log("Supplied DAI on aave");

      //borrow USDC from aave
      await aave.connect(wallet0).borrow(USDC, parseUnits("3", 6), 2, 3228, wallet.address);
      console.log("Borrowed USDC from aave");
    });

    it("Should check position of user", async () => {
      expect(await aDai.connect(wallet0).balanceOf(wallet.address)).to.be.gte(
        new BigNumber(10).multipliedBy(1e18).toString()
      );

      expect(await usdcToken.connect(wallet0).balanceOf(wallet.address)).to.be.gte(
        new BigNumber(3).multipliedBy(1e6).toString()
      );
    });
  });

  describe("Deployment", async () => {
    it("Should set correct name", async () => {
      expect(await connector.name()).to.eq("Aave-v3-import-permit-v1");
    });
  });

  describe("DSA wallet setup", async () => {
    it("Should build DSA v2", async () => {
      dsaWallet0 = await buildDSAv2(wallet.address);
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

  describe("Aave position migration", async () => {
    it("Should migrate Aave position", async () => {
      const DOMAIN_SEPARATOR = await aDai.connect(wallet0).DOMAIN_SEPARATOR();
      const PERMIT_TYPEHASH = "0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9";

      let nonce = (await aDai.connect(wallet0).nonces(wallet.address)).toNumber();
      //Approving max amount
      const amount = ethers.constants.MaxUint256;
      const expiry = Date.now() + 20 * 60;

      const digest = keccak256(
        ethers.utils.solidityPack(
          ["bytes1", "bytes1", "bytes32", "bytes32"],
          [
            "0x19",
            "0x01",
            DOMAIN_SEPARATOR,
            keccak256(
              defaultAbiCoder.encode(
                ["bytes32", "address", "address", "uint256", "uint256", "uint256"],
                [PERMIT_TYPEHASH, wallet.address, dsaWallet0.address, amount, nonce, expiry]
              )
            )
          ]
        )
      );
      const { v, r, s } = ecsign(Buffer.from(digest.slice(2), "hex"), Buffer.from(wallet.privateKey.slice(2), "hex"));
      const amount0 = new BigNumber(await usdcToken.connect(wallet0).balanceOf(wallet.address));
      const amountB = new BigNumber(amount0.toString()).multipliedBy(5).dividedBy(1e4);
      const amountWithFee = amount0.plus(amountB);

      const flashSpells = [
        {
          connector: "AAVE-V3-IMPORT-PERMIT-X",
          method: "importAave",
          args: [
            wallet.address,
            [[DAI], [USDC], false, [amountB.toFixed(0)]],
            [[v], [ethers.utils.hexlify(r)], [ethers.utils.hexlify(s)], [expiry]]
          ]
        },
        {
          connector: "INSTAPOOL-C",
          method: "flashPayback",
          args: [USDC, amountWithFee.toFixed(0), 0, 0]
        }
      ];

      const spells = [
        {
          connector: "INSTAPOOL-C",
          method: "flashBorrowAndCast",
          args: [USDC, amount0.toString(), 5, encodeFlashcastData(flashSpells), "0x"]
        }
      ];
      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet.address);
      const receipt = await tx.wait();
    });

    it("Should check DSA AAVE position", async () => {
      expect(await aDai.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.gte(
        new BigNumber(10).multipliedBy(1e18).toString()
      );
    });
  });
});
