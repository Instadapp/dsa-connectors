import { expect, should } from "chai";
import hre, { ethers, waffle } from "hardhat";
import type { Signer, Contract } from "ethers";
import { ecsign, ecrecover, pubToAddress } from "ethereumjs-util";
import { keccak256 } from "@ethersproject/keccak256";
import { defaultAbiCoder } from "@ethersproject/abi";
import { BigNumber } from "bignumber.js";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { abis } from "../../../scripts/constant/abis";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { parseEther, parseUnits } from "ethers/lib/utils";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import encodeFlashcastData from "../../../scripts/tests/encodeFlashcastData";
import { ConnectV2CompoundV3__factory, IERC20__factory } from "../../../typechain";
import { tokens } from "../../../scripts/tests/mainnet/tokens";
const { provider } = waffle;

const ABI = [
  "function balanceOf(address account) public view returns (uint256)",
  "function approve(address spender, uint256 amount) external returns(bool)",
  "function transfer(address recipient, uint256 amount) external returns (bool)"
];

const market = "0xc3d688B66703497DAA19211EEdff47f25384cdc3";
const user = "0x0a904e5e342d853952ad8159502dc1a29f9b084e";
const wethWhale = "0xf04a5cc80b1e94c69b48f5ee68a08cd2f09a7c3e";
const account = "0x72a53cdbbcc1b9efa39c834a540550e23463aacb";
const mnemonic = "test test test test test test test test test test test junk";
const connectorName = "COMPOUND-V3-X";

const cometABI = [
  {
    inputs: [{ internalType: "address", name: "account", type: "address" }],
    name: "balanceOf",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [{ internalType: "address", name: "account", type: "address" }],
    name: "borrowBalanceOf",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "asset", type: "address" },
      { internalType: "uint256", name: "amount", type: "uint256" }
    ],
    name: "supply",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "dst", type: "address" },
      { internalType: "address", name: "asset", type: "address" },
      { internalType: "uint256", name: "amount", type: "uint256" }
    ],
    name: "supplyTo",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "dst", type: "address" },
      { internalType: "uint256", name: "amount", type: "uint256" }
    ],
    name: "transfer",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "dst", type: "address" },
      { internalType: "address", name: "asset", type: "address" },
      { internalType: "uint256", name: "amount", type: "uint256" }
    ],
    name: "transferAsset",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "src", type: "address" },
      { internalType: "address", name: "dst", type: "address" },
      { internalType: "address", name: "asset", type: "address" },
      { internalType: "uint256", name: "amount", type: "uint256" }
    ],
    name: "transferAssetFrom",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "", type: "address" },
      { internalType: "address", name: "", type: "address" }
    ],
    name: "userCollateral",
    outputs: [
      { internalType: "uint128", name: "balance", type: "uint128" },
      { internalType: "uint128", name: "_reserved", type: "uint128" }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [{ internalType: "address", name: "", type: "address" }],
    name: "userNonce",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "asset", type: "address" },
      { internalType: "uint256", name: "amount", type: "uint256" }
    ],
    name: "withdraw",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  }
];

const comet = new ethers.Contract(market, cometABI);
const wethContract = new ethers.Contract(tokens.weth.address, ABI);

describe("Import Compound v3 Position", function () {
  let dsaWallet0: any;
  let masterSigner: Signer;
  let signer: any;
  let wallet0: any;
  let walletSigner: any;
  let instaConnectorsV2: Contract;
  let connector: any;

  const wallets = provider.getWallets();
  const [wallet1, wallet2, wallet3] = wallets;

  const wallet = ethers.Wallet.fromMnemonic(mnemonic);

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            //@ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 15444500
          }
        }
      ]
    });
    masterSigner = await getMasterSigner();

    await hre.network.provider.send("hardhat_setBalance", [account, ethers.utils.parseEther("10").toHexString()]);
    await hre.network.provider.send("hardhat_setBalance", [wethWhale, ethers.utils.parseEther("10").toHexString()]);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [wethWhale]
    });
    signer = await ethers.getSigner(wethWhale);
    [wallet0] = await ethers.getSigners();

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [wallet.address]
    });
    walletSigner = await ethers.getSigner(wallet.address);
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2CompoundV3__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
  });

  describe("check user Compound position", async () => {
    it("Should create Compound v3 position of DAI(collateral) and ETH(debt)", async () => {
      await wethContract.connect(signer).transfer(wallet.address, parseEther("100"));
      // approve WETH to market

      await wethContract.connect(walletSigner).approve(market, parseEther("100"));

      //deposit WETH in Compound
      await comet.connect(walletSigner).supply(tokens.weth.address, parseEther("100"));
      console.log("Supplied WETH on compound");

      //borrow Base from compound
      await comet.connect(walletSigner).withdraw(tokens.usdc.address, parseUnits("100", 6));
      console.log("Borrowed USDC from compound");
    });

    it("Should check position of user", async () => {
      expect((await comet.connect(signer).userCollateral(wallet.address, tokens.weth.address)).balance).to.be.gte(
        new BigNumber(100).multipliedBy(1e18).toString()
      );

      expect(await comet.connect(signer).borrowBalanceOf(wallet.address)).to.be.gte(
        new BigNumber(100).multipliedBy(1e6).toString()
      );
    });
  });

  describe("Deployment", async () => {
    it("Should set correct name", async () => {
      expect(await connector.name()).to.eq("CompoundV3-v1.0");
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
        value: ethers.utils.parseEther("10")
      });

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
    });
  });

  describe("Compound position migration", async () => {
    it("Should migrate Compound position", async () => {
      const DOMAIN_TYPEHASH = keccak256(
        ethers.utils.toUtf8Bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
      );
      const PERMIT_TYPEHASH = keccak256(
        ethers.utils.toUtf8Bytes(
          "Authorization(address owner,address manager,bool isAllowed,uint256 nonce,uint256 expiry)"
        )
      );
      const name = keccak256(ethers.utils.toUtf8Bytes("Compound USDC"));
      const version = keccak256(ethers.utils.toUtf8Bytes("0"));
      const chainId = 1;
      const DOMAIN_SEPARATOR = keccak256(
        defaultAbiCoder.encode(
          ["bytes32", "bytes32", "bytes32", "uint256", "address"],
          [DOMAIN_TYPEHASH, name, version, chainId, market]
        )
      );

      let nonce = (await comet.connect(walletSigner).userNonce(wallet.address)).toNumber();
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
                [PERMIT_TYPEHASH, wallet.address, dsaWallet0.address, true, nonce, expiry]
              )
            )
          ]
        )
      );
      const { v, r, s } = ecsign(Buffer.from(digest.slice(2), "hex"), Buffer.from(wallet.privateKey.slice(2), "hex"));

      let buffer = ethers.utils.parseUnits("100", 6).toNumber();
      let amount0 = new BigNumber(await comet.connect(wallet0).borrowBalanceOf(wallet.address)).plus(buffer);
      let amountB = new BigNumber(amount0.toString()).multipliedBy(5).dividedBy(1e4);
      let amountWithFee = amount0.plus(amountB);
      const spells1 = [
        {
          connector: "COMPOUND-V3-X",
          method: "toggleAccountManagerWithPermit",
          args: [wallet.address, dsaWallet0.address, true, nonce, expiry, v, r, s]
        }
      ];

      let tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells1), wallet0.address);
      const receipt = await tx.wait();
      console.log("DSA Permitted as manager");

      const flashSpells = [
        {
          connector: "COMPOUND-V3-X",
          method: "paybackOnBehalf",
          args: [market, tokens.usdc.address, wallet.address, ethers.constants.MaxUint256, 0, 0]
        },
        {
          connector: "COMPOUND-V3-X",
          method: "transferAssetFromUsingManager",
          args: [market, tokens.eth.address, wallet.address, dsaWallet0.address, ethers.constants.MaxUint256, 0, 0]
        },
        {
          connector: "COMPOUND-V3-X",
          method: "borrow",
          args: [market, tokens.usdc.address, amountWithFee.toFixed(0), 0, 0]
        },
        {
          connector: "INSTAPOOL-C",
          method: "flashPayback",
          args: [tokens.usdc.address, amountWithFee.toFixed(0), 0, 0]
        }
      ];
      const spells = [
        {
          connector: "INSTAPOOL-C",
          method: "flashBorrowAndCast",
          args: [tokens.usdc.address, amount0.toFixed(), 5, encodeFlashcastData(flashSpells), "0x"]
        }
      ];

      tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
      await tx.wait();
    });

    it("Should check DSA COMPOUND position", async () => {
      expect((await comet.connect(wallet0).userCollateral(dsaWallet0.address, tokens.weth.address)).balance).to.be.gte(
        ethers.utils.parseEther("100")
      );
      expect(await comet.connect(wallet0).borrowBalanceOf(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseUnits("100", 6)
      );
    });
  });
});
