import { expect } from "chai";
import hre from "hardhat";
const { waffle, ethers } = hre;
const { provider, deployContract } = waffle;

import { Signer, Contract } from "ethers";
import { BigNumber } from "bignumber.js";

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { tokens, tokenMapping } from "../../../scripts/tests/mainnet/tokens";
import { abis } from "../../../scripts/constant/abis";
import { constants } from "../../../scripts/constant/constant";
import { ConnectV2CompoundV3__factory } from "../../../typechain";
import { MaxUint256 } from "@uniswap/sdk-core";

describe("Compound III", function () {
  const connectorName = "COMPOUND-V3-TEST-A";
  const market = "0xc3d688B66703497DAA19211EEdff47f25384cdc3";
  const base = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
  const account = "0x10bf1dcb5ab7860bab1c3320163c6dddf8dcc0e4";

  const ABI = ["function balanceOf(address account) public view returns (uint256)"];
  const wethContract = new ethers.Contract(tokens.weth.address, ABI);
  const baseContract = new ethers.Contract(base, ABI);

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
      inputs: [],
      name: "baseBorrowMin",
      outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
      stateMutability: "view",
      type: "function"
    },
    {
      inputs: [],
      name: "baseMinForRewards",
      outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
      stateMutability: "view",
      type: "function"
    },
    {
      inputs: [],
      name: "baseToken",
      outputs: [{ internalType: "address", name: "", type: "address" }],
      stateMutability: "view",
      type: "function"
    },
    {
      inputs: [],
      name: "decimals",
      outputs: [{ internalType: "uint8", name: "", type: "uint8" }],
      stateMutability: "view",
      type: "function"
    },
    {
      inputs: [{ internalType: "address", name: "priceFeed", type: "address" }],
      name: "getPrice",
      outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
      stateMutability: "view",
      type: "function"
    },
    {
      inputs: [
        { internalType: "address", name: "owner", type: "address" },
        { internalType: "address", name: "manager", type: "address" }
      ],
      name: "hasPermission",
      outputs: [{ internalType: "bool", name: "", type: "bool" }],
      stateMutability: "view",
      type: "function"
    },
    {
      inputs: [],
      name: "numAssets",
      outputs: [{ internalType: "uint8", name: "", type: "uint8" }],
      stateMutability: "view",
      type: "function"
    },
    {
      inputs: [
        { internalType: "address", name: "asset", type: "address" },
        { internalType: "uint256", name: "baseAmount", type: "uint256" }
      ],
      name: "quoteCollateral",
      outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
      stateMutability: "view",
      type: "function"
    },
    {
      inputs: [{ internalType: "address", name: "", type: "address" }],
      name: "userBasic",
      outputs: [
        { internalType: "int104", name: "principal", type: "int104" },
        { internalType: "uint64", name: "baseTrackingIndex", type: "uint64" },
        { internalType: "uint64", name: "baseTrackingAccrued", type: "uint64" },
        { internalType: "uint16", name: "assetsIn", type: "uint16" },
        { internalType: "uint8", name: "_reserved", type: "uint8" }
      ],
      stateMutability: "view",
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
    }
  ];

  let dsaWallet0: any;
  let dsaWallet1: any;
  let dsaWallet2: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;
  let signer: any;

  const comet = new ethers.Contract(market, cometABI);

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;

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
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2CompoundV3__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
    console.log("Connector address", connector.address);

    await hre.network.provider.send("hardhat_setBalance", [account, ethers.utils.parseEther("10").toHexString()]);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [account]
    });

    signer = await ethers.getSigner(account);
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
      dsaWallet1 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet1.address).to.be.true;
      dsaWallet2 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet2.address).to.be.true;
    });

    it("Deposit ETH into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
      await wallet0.sendTransaction({
        to: dsaWallet1.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
    });
  });

  describe("Main", function () {
    //deposit asset
    it("Should supply ETH collateral in Compound V3", async function () {
      const amount = ethers.utils.parseEther("5"); // 1 ETH
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [market, tokens.eth.address, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(ethers.utils.parseEther("5"));
      expect((await comet.connect(signer).userCollateral(dsaWallet0.address, tokens.weth.address)).balance).to.be.gte(
        ethers.utils.parseEther("5")
      );
    });

    //deposit asset on behalf of
    it("Should supply on behalf of dsaWallet0 ETH collateral in Compound V3", async function () {
      const amount = ethers.utils.parseEther("1"); // 1 ETH
      const spells = [
        {
          connector: connectorName,
          method: "depositOnBehalf",
          args: [market, tokens.eth.address, dsaWallet0.address, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet1.address)).to.be.lte(ethers.utils.parseEther("9"));
      expect((await comet.connect(wallet0).userCollateral(dsaWallet0.address, tokens.weth.address)).balance).to.be.gte(
        ethers.utils.parseEther("6")
      );
    });

    it("Should borrow and payback base token from Compound", async function () {
      const amount = ethers.utils.parseUnits("150", 6);
      const spells = [
        {
          connector: connectorName,
          method: "borrow",
          args: [market, amount, 0, 0]
        },
        {
          connector: connectorName,
          method: "payback",
          args: [market, ethers.utils.parseUnits("50", 6), 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await comet.connect(wallet0).borrowBalanceOf(dsaWallet0.address)).to.be.equal(
        ethers.utils.parseUnits("100", 6)
      );
      console.log(baseContract);
      expect(await baseContract.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.equal(
        ethers.utils.parseUnits("100", 6)
      );
    });

    it("should payback base token from Compound", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "payback",
          args: [market, ethers.constants.MaxUint256, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await comet.connect(signer).balanceOf(dsaWallet0.address)).to.be.equal(ethers.utils.parseUnits("0", 6));
    });

    it("Should borrow on behalf of from Compound", async function () {
      const spells1 = [
        {
          connector: connectorName,
          method: "deposit",
          args: [market, tokens.eth.address, ethers.utils.parseEther("6"), 0, 0]
        }
      ];

      const tx1 = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells1), wallet1.address);
      const amount = ethers.utils.parseUnits("100", 6);
      const spells = [
        {
          connector: connectorName,
          method: "borrowOnBehalf",
          args: [market, dsaWallet1.address, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(new BigNumber(await comet.connect(signer).borrowBalanceOf(dsaWallet0.address)).toFixed()).to.be.equal(
        ethers.utils.parseUnits("100", 6)
      );
    });

    it("Should payback on behalf of from Compound", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "paybackOnBehalf",
          args: [market, dsaWallet0.address, ethers.constants.MaxUint256, 0, 0]
        }
      ];

      const tx = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await comet.connect(signer).borrowBalanceOf(dsaWallet0.address)).to.be.equal(
        ethers.utils.parseUnits("0", 6)
      );
    });

    it("should allow manager for dsaWallet0's collateral", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "allow",
          args: [market, dsaWallet2.address, true]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
    });

    it("should withdraw some ETH collateral", async function () {
      const amount = ethers.utils.parseEther("2");
      const spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: [market, tokens.eth.address, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect((await comet.connect(signer).userCollateral(dsaWallet0.address, tokens.weth.address)).balance).to.be.gte(
        ethers.utils.parseEther("4")
      );
      expect(await wethContract.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("2"));
    });

    it("manager should be able to withdraw collateral from the position", async function () {
      const amount = ethers.constants.MaxUint256;
      const spells = [
        {
          connector: connectorName,
          method: "withdrawFrom",
          args: [market, tokens.eth.address, dsaWallet0.address, dsaWallet1.address, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet2.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect((await comet.connect(signer).userCollateral(dsaWallet0.address, tokens.weth.address)).balance).to.be.gte(
        ethers.utils.parseEther("0")
      );
      expect(await wethContract.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("2"));
      expect(await wethContract.connect(wallet0).balanceOf(dsaWallet1.address)).to.be.gte(ethers.utils.parseEther("5"));
    });
  });
});
