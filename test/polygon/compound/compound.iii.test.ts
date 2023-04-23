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
import { addresses } from "../../../scripts/tests/polygon/addresses";
import { tokens, tokenMapping } from "../../../scripts/tests/polygon/tokens";
import { abis } from "../../../scripts/constant/abis";
import { constants } from "../../../scripts/constant/constant";
import { ConnectV2CompoundV3Polygon__factory } from "../../../typechain";
import { MaxUint256 } from "@uniswap/sdk-core";

describe("Compound III", async function () {
  const connectorName = "COMPOUND-POLYGON-V3-TEST-A";
  const market = "0xF25212E676D1F7F89Cd72fFEe66158f541246445";
  const base = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
  const account = "0xF25212E676D1F7F89Cd72fFEe66158f541246445";
  const wethWhale = "0x06959153B974D0D5fDfd87D561db6d8d4FA0bb0B";

  const ABI = [
    "function balanceOf(address account) public view returns (uint256)",
    "function approve(address spender, uint256 amount) external returns(bool)",
    "function transfer(address recipient, uint256 amount) external returns (bool)"
  ];
  let wmaticContract: any;
  let baseContract: any;

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
  let dsaWallet3: any;
  let wallet: any;
  let dsa0Signer: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;
  let signer: any; 
  let wethSigner: any;

  let comet: any;

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
            // blockNumber: 41860206
          }
        }
      ]
    });
    masterSigner = await getMasterSigner();
    await hre.network.provider.send("hardhat_setBalance", [
      await masterSigner.getAddress(),
      "0x3635c9adc5de9fffff",
    ]);

    signer = await ethers.getSigner(account);

    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2CompoundV3Polygon__factory,
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

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [wethWhale]
    });
    wethSigner = await ethers.getSigner(wethWhale);
    baseContract = new ethers.Contract(base, ABI, wethSigner)
    wmaticContract = new ethers.Contract(tokens.wmatic.address, ABI, wethSigner)
    comet = new ethers.Contract(market, cometABI, wethSigner)
  });

  it("Should have contracts deployed.", async function () {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  it("Should build DSA v2", async function () {
    dsaWallet0 = await buildDSAv2(wallet0.address);
    expect(!!dsaWallet0.address).to.be.true;
    dsaWallet1 = await buildDSAv2(wallet0.address);
    expect(!!dsaWallet1.address).to.be.true;
    dsaWallet2 = await buildDSAv2(wallet0.address);
    expect(!!dsaWallet2.address).to.be.true;
    dsaWallet3 = await buildDSAv2(wallet0.address);
    expect(!!dsaWallet3.address).to.be.true;
    wallet = await ethers.getSigner(dsaWallet0.address);
    expect(!!dsaWallet1.address).to.be.true;
  });

  describe("DSA wallet setup", function () {
    it("Deposit Matic into DSA wallet", async function () {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [wallet.address]
      });

      dsa0Signer = await ethers.getSigner(wallet.address);
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("1000")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("1000"));
      await wallet0.sendTransaction({
        to: dsaWallet1.address,
        value: ethers.utils.parseEther("1000")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("1000"));
      await wallet0.sendTransaction({
        to: dsaWallet3.address,
        value: ethers.utils.parseEther("1000")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("1000"));
    });
  });

  describe("Main", function () {
    //deposit asset
    it("Should supply Matic collateral in Compound V3", async function () {
      const amount = ethers.utils.parseEther("500"); // 5 Matic
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [market, tokens.matic.address, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(ethers.utils.parseEther("500"));
      expect((await comet.connect(signer).userCollateral(dsaWallet0.address, tokens.wmatic.address)).balance).to.be.gte(
        ethers.utils.parseEther("500")
      );
    });

    //deposit asset on behalf of
    it("Should supply  Matic collateral on behalf of dsaWallet0 in Compound V3", async function () {
      const amount = ethers.utils.parseEther("100"); // 100 Matic
      const spells = [
        {
          connector: connectorName,
          method: "depositOnBehalf",
          args: [market, tokens.matic.address, dsaWallet0.address, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet1.address)).to.be.lte(ethers.utils.parseEther("900"));
      expect((await comet.connect(wallet0).userCollateral(dsaWallet0.address, tokens.wmatic.address)).balance).to.be.gte(
        ethers.utils.parseEther("600")
      );
    });

    it("Should borrow and payback base token from Compound", async function () {
      const amount = ethers.utils.parseUnits("150", 6);
      const spells = [
        {
          connector: connectorName,
          method: "borrow",
          args: [market, base, amount, 0, 0]
        },
        {
          connector: connectorName,
          method: "payback",
          args: [market, base, ethers.utils.parseUnits("50", 6), 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await comet.connect(wallet0).borrowBalanceOf(dsaWallet0.address)).to.be.equal(
        ethers.utils.parseUnits("100", 6)
      );
      expect(await baseContract.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.equal(
        ethers.utils.parseUnits("100", 6)
      );
    });

    it("should allow manager for dsaWallet0's collateral and base", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "toggleAccountManager",
          args: [market, dsaWallet2.address, true]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
    });

    it("should payback base token on Compound using manager", async function () {
      await baseContract.connect(signer).transfer(dsaWallet0.address, ethers.utils.parseUnits("5", 6));

      const amount = ethers.utils.parseUnits("102", 6);
      await baseContract.connect(dsa0Signer).approve(market, amount);

      const spells = [
        {
          connector: connectorName,
          method: "paybackFromUsingManager",
          args: [market, base, dsaWallet0.address, dsaWallet0.address, ethers.constants.MaxUint256, 0, 0]
        }
      ];

      const tx = await dsaWallet2.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await comet.connect(signer).borrowBalanceOf(dsaWallet0.address)).to.be.equal(
        ethers.utils.parseUnits("0", 6)
      );
    });

    it("Should borrow to another dsa from Compound", async function () {
      const amount = ethers.utils.parseUnits("100", 6);
      const spells = [
        {
          connector: connectorName,
          method: "borrowTo",
          args: [market, base, dsaWallet1.address, amount, 0, 0]
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
          args: [market, base, dsaWallet0.address, ethers.constants.MaxUint256, 0, 0]
        }
      ];

      const tx = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await comet.connect(signer).borrowBalanceOf(dsaWallet0.address)).to.be.equal(
        ethers.utils.parseUnits("0", 6)
      );
    });

    it("should withdraw some Matic collateral", async function () {
      let initialBal = await ethers.provider.getBalance(dsaWallet0.address);
      const amount_ = ethers.utils.parseEther("200");
      const spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: [market, tokens.matic.address, amount_, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect((await comet.connect(signer).userCollateral(dsaWallet0.address, tokens.wmatic.address)).balance).to.be.gte(
        ethers.utils.parseEther("400")
      );
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(initialBal.add(amount_).toString());
    });

    it("manager should be able to withdraw collateral from the position and transfer", async function () {
      await wallet1.sendTransaction({
        to: tokens.wmatic.address,
        value: ethers.utils.parseEther("1000")
      });
      const amount = ethers.constants.MaxUint256;
      const spells = [
        {
          connector: connectorName,
          method: "withdrawOnBehalfAndTransfer",
          args: [market, tokens.matic.address, dsaWallet0.address, dsaWallet1.address, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet2.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect((await comet.connect(signer).userCollateral(dsaWallet0.address, tokens.wmatic.address)).balance).to.be.gte(
        ethers.utils.parseEther("0")
      );
      expect(await wmaticContract.connect(wallet0).balanceOf(dsaWallet1.address)).to.be.gte(ethers.utils.parseEther("400"));
    });

    it("Should withdraw collateral to another DSA", async function () {
      const spells1 = [
        {
          connector: connectorName,
          method: "deposit",
          args: [market, tokens.matic.address, ethers.utils.parseEther("500"), 0, 0]
        }
      ];

      const tx1 = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells1), wallet1.address);
      let initialBal = await ethers.provider.getBalance(dsaWallet0.address);

      const amount = ethers.utils.parseEther("200");
      const spells = [
        {
          connector: connectorName,
          method: "withdrawTo",
          args: [market, tokens.matic.address, dsaWallet0.address, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await wmaticContract.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.gte(amount);

      expect((await comet.connect(signer).userCollateral(dsaWallet1.address, tokens.wmatic.address)).balance).to.be.gte(
        ethers.utils.parseEther("300")
      );
    });

    it("Should withdraw collateral to another DSA", async function () {
      const spells1 = [
        {
          connector: connectorName,
          method: "deposit",
          args: [market, tokens.matic.address, ethers.utils.parseEther("300"), 0, 0]
        }
      ];

      const tx1 = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells1), wallet1.address);
      let initialBal = await ethers.provider.getBalance(dsaWallet0.address);

      const amount = ethers.utils.parseEther("200");
      const spells = [
        {
          connector: connectorName,
          method: "withdrawTo",
          args: [market, tokens.matic.address, dsaWallet0.address, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(initialBal.add(amount));

      expect((await comet.connect(signer).userCollateral(dsaWallet1.address, tokens.wmatic.address)).balance).to.be.gte(
        ethers.utils.parseEther("100")
      );
    });

    it("should transfer matic from dsaWallet1 to dsaWallet0 position", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "transferAsset",
          args: [market, tokens.matic.address, dsaWallet0.address, ethers.utils.parseEther("300"), 0, 0]
        }
      ];

      const tx = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect((await comet.connect(signer).userCollateral(dsaWallet1.address, tokens.wmatic.address)).balance).to.be.gte(
        ethers.utils.parseEther("0")
      );
      expect((await comet.connect(signer).userCollateral(dsaWallet0.address, tokens.wmatic.address)).balance).to.be.gte(
        ethers.utils.parseEther("300")
      );
    });

    it("should transfer base token from dsaWallet1 to dsaWallet0 position", async function () {
      await baseContract.connect(wethSigner).transfer(dsaWallet1.address, ethers.utils.parseUnits("1000", 6));

      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [market, base, ethers.constants.MaxUint256, 0, 0]
        }
      ];
      const tx = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      let initialBal = await baseContract.connect(signer).balanceOf(dsaWallet1.address);
      let spells1 = [
        {
          connector: connectorName,
          method: "transferAsset",
          args: [market, base, dsaWallet0.address, ethers.constants.MaxUint256, 0, 0]
        }
      ];

      const tx1 = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells1), wallet1.address);
      const receipt1 = await tx.wait();
      expect(await comet.connect(signer).balanceOf(dsaWallet1.address)).to.be.lte(ethers.utils.parseUnits("0", 6));
      expect(await comet.connect(signer).balanceOf(dsaWallet0.address)).to.be.gte(initialBal);
    });

    it("should transfer base token using manager from dsaWallet0 to dsaWallet1 position", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "transferAssetOnBehalf",
          args: [market, base, dsaWallet0.address, dsaWallet1.address, ethers.constants.MaxUint256, 0, 0]
        }
      ];
      let initialBal = await baseContract.connect(signer).balanceOf(dsaWallet0.address);

      const tx = await dsaWallet2.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await comet.connect(signer).balanceOf(dsaWallet0.address)).to.be.lte(ethers.utils.parseUnits("0", 6));
      expect(await comet.connect(signer).balanceOf(dsaWallet1.address)).to.be.gte(initialBal);
    });

    it("should deposit weth using manager", async function () {
      await wmaticContract.connect(signer).transfer(dsaWallet0.address, ethers.utils.parseEther("1000"));
      let initialBal = await wmaticContract.connect(wallet0).balanceOf(dsaWallet0.address);

      const amount = ethers.utils.parseEther("100");
      await wmaticContract.connect(dsa0Signer).approve(market, amount);

      const spells = [
        {
          connector: connectorName,
          method: "depositFromUsingManager",
          args: [market, tokens.matic.address, dsaWallet0.address, dsaWallet1.address, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet2.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect((await comet.connect(signer).userCollateral(dsaWallet1.address, tokens.wmatic.address)).balance).to.be.gte(
        ethers.utils.parseEther("100")
      );
      expect(await wmaticContract.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.lte(initialBal.sub(amount));
    });

    it("should allow manager for dsaWallet0's collateral", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "toggleAccountManager",
          args: [market, dsaWallet2.address, true]
        }
      ];

      const tx = await dsaWallet3.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
    });
    it("should borrow on behalf using manager", async function () {
      let initialBal = await baseContract.connect(wallet0).balanceOf(dsaWallet0.address);
      await wallet0.sendTransaction({
        to: dsaWallet3.address,
        value: ethers.utils.parseEther("1500")
      });
      const spells1 = [
        {
          connector: connectorName,
          method: "deposit",
          args: [market, tokens.matic.address, ethers.utils.parseEther("1500"), 0, 0]
        }
      ];
      const tx1 = await dsaWallet3.connect(wallet0).cast(...encodeSpells(spells1), wallet1.address);
      const amount = ethers.utils.parseUnits("500", 6);
      const spells = [
        {
          connector: connectorName,
          method: "borrowOnBehalfAndTransfer",
          args: [market, base, dsaWallet3.address, dsaWallet0.address, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet2.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(new BigNumber(await comet.connect(signer).borrowBalanceOf(dsaWallet3.address)).toFixed()).to.be.equal(
        ethers.utils.parseUnits("500", 6)
      );
      expect(await baseContract.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.equal(initialBal.add(amount));
    });

    it("should transferAsset collateral using manager", async function () {
      let bal1 = (await comet.connect(signer).userCollateral(dsaWallet1.address, tokens.wmatic.address)).balance;
      let bal0 = (await comet.connect(signer).userCollateral(dsaWallet0.address, tokens.wmatic.address)).balance;
      const spells = [
        {
          connector: connectorName,
          method: "transferAssetOnBehalf",
          args: [market, tokens.matic.address, dsaWallet0.address, dsaWallet1.address, ethers.utils.parseEther("100"), 0, 0]
        }
      ];

      const tx = await dsaWallet2.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect((await comet.connect(signer).userCollateral(dsaWallet1.address, tokens.wmatic.address)).balance).to.be.gte(
        bal1.add(ethers.utils.parseEther("100")).toString()
      );
      expect((await comet.connect(signer).userCollateral(dsaWallet0.address, tokens.wmatic.address)).balance).to.be.gte(
        bal0.sub(ethers.utils.parseEther("100")).toString()
      );
    });

    //can buy only when target reserves not reached.

    // it("should buy collateral", async function () {
    //   //deposit 10 usdc(base token) to dsa
    //   await baseContract.connect(signer).transfer(dsaWallet0.address, ethers.utils.parseUnits("10", 6));
    //   console.log(await baseContract.connect(signer).balanceOf(dsaWallet0.address));

    //   //dsawallet0 --> collateral 0eth, balance 9eth 10usdc
    //   //dsaWallet1 --> balance 2eth coll: 3eth
    //   const amount = ethers.utils.parseUnits("1",6);
    //   const bal = await baseContract.connect(signer).balanceOf(dsaWallet0.address);
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "buyCollateral",
    //       args: [market, tokens.link.address, dsaWallet0.address, amount, bal, 0, 0]
    //     }
    //   ];

    //   const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
    //   const receipt = await tx.wait();
    //   expect(new BigNumber(await linkContract.connect(signer).balanceOf(dsaWallet0.address)).toFixed()).to.be.gte(
    //     ethers.utils.parseEther("100")
    //   );

    //   //dsawallet0 --> collateral 0eth, balance 9eth >1link
    //   //dsaWallet1 --> balance 2eth coll: 3eth
    // });
  });
});
