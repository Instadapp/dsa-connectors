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
import { ConnectV2CompoundV3Rewards__factory, ConnectV2CompoundV3__factory } from "../../../typechain";

describe("Compound III Rewards", function () {
  let connectorName = "COMPOUND-V3-REWARDS-TEST-A";
  const market = "0xc3d688B66703497DAA19211EEdff47f25384cdc3";
  const rewards = "0x1B0e765F6224C21223AeA2af16c1C46E38885a40";
  const base = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
  const account = "0x72a53cdbbcc1b9efa39c834a540550e23463aacb";
  const wethWhale = "0x1c11ba15939e1c16ec7ca1678df6160ea2063bc5";
  const baseWhale = "0x72a53cdbbcc1b9efa39c834a540550e23463aacb";

  const ABI = [
    "function balanceOf(address account) public view returns (uint256)",
    "function approve(address spender, uint256 amount) external returns(bool)",
    "function transfer(address recipient, uint256 amount) external returns (bool)"
  ];
  const wethContract = new ethers.Contract(tokens.weth.address, ABI);
  const baseContract = new ethers.Contract(base, ABI);

  const cometABI = [
    {
      inputs: [
        { internalType: "address", name: "comet", type: "address" },
        { internalType: "address", name: "src", type: "address" },
        { internalType: "bool", name: "shouldAccrue", type: "bool" }
      ],
      name: "claim",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function"
    },
    {
      inputs: [
        { internalType: "address", name: "comet", type: "address" },
        { internalType: "address", name: "src", type: "address" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "bool", name: "shouldAccrue", type: "bool" }
      ],
      name: "claimTo",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function"
    },
    {
      inputs: [
        { internalType: "address", name: "comet", type: "address" },
        { internalType: "address", name: "account", type: "address" }
      ],
      name: "getRewardOwed",
      outputs: [
        {
          components: [
            { internalType: "address", name: "token", type: "address" },
            { internalType: "uint256", name: "owed", type: "uint256" }
          ],
          internalType: "struct CometRewards.RewardOwed",
          name: "",
          type: "tuple"
        }
      ],
      stateMutability: "nonpayable",
      type: "function"
    },
    {
      inputs: [{ internalType: "address", name: "", type: "address" }],
      name: "rewardConfig",
      outputs: [
        { internalType: "address", name: "token", type: "address" },
        { internalType: "uint64", name: "rescaleFactor", type: "uint64" },
        { internalType: "bool", name: "shouldUpscale", type: "bool" }
      ],
      stateMutability: "view",
      type: "function"
    },
    {
      inputs: [
        { internalType: "address", name: "", type: "address" },
        { internalType: "address", name: "", type: "address" }
      ],
      name: "rewardsClaimed",
      outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
      stateMutability: "view",
      type: "function"
    }
  ];

  const marketABI = [
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
  let wallet: any;
  let dsa0Signer: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;
  let connectorMain: any;
  let signer: any;
  let wethSigner: any;
  let usdcSigner: any;

  const cometReward = new ethers.Contract(rewards, cometABI);
  const comet = new ethers.Contract(market, marketABI);

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
      contractArtifact: ConnectV2CompoundV3Rewards__factory,
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

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [baseWhale]
    });
    usdcSigner = await ethers.getSigner(baseWhale);
    await hre.network.provider.send("hardhat_setBalance", [
      usdcSigner.address,
      ethers.utils.parseEther("10").toHexString()
    ]);
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
      wallet = await ethers.getSigner(dsaWallet0.address);
      expect(!!dsaWallet1.address).to.be.true;
    });

    it("Deposit ETH into DSA wallet", async function () {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [wallet.address]
      });

      dsa0Signer = await ethers.getSigner(wallet.address);
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
      await wallet0.sendTransaction({
        to: dsaWallet1.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet1.address)).to.be.gte(ethers.utils.parseEther("10"));
    });

    it("should deposit USDC in dsa wallet", async function () {
      await baseContract.connect(usdcSigner).transfer(dsaWallet0.address, ethers.utils.parseUnits("500", 6));

      expect(await baseContract.connect(usdcSigner).balanceOf(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseUnits("500", 6)
      );
    });
  });

  describe("Main", function () {
    //deposit asset
    it("Should supply USDC in Compound V3", async function () {
      connectorName = "COMPOUND-V3-TEST-A";
      connectorMain = await deployAndEnableConnector({
        connectorName,
        contractArtifact: ConnectV2CompoundV3__factory,
        signer: masterSigner,
        connectors: instaConnectorsV2
      });
      const amount = ethers.utils.parseUnits("400", 6);
      const spells = [
        {
          connector: "COMPOUND-V3-TEST-A",
          method: "deposit",
          args: [market, base, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(new BigNumber(await baseContract.connect(signer).balanceOf(dsaWallet0.address)).toFixed(0)).to.be.lte(
        ethers.utils.parseUnits("100", 6)
      );
      expect(new BigNumber(await comet.connect(signer).balanceOf(dsaWallet0.address)).toFixed(0)).to.be.gte(
        ethers.utils.parseUnits("399", 6)
      );
    });

    let connector_ = "COMPOUND-V3-REWARDS-TEST-A";
    it("Should claim rewards", async function () {
      let reward = (await cometReward.connect(signer).rewardConfig(market)).token;
      let rewardInterface = new ethers.Contract(reward, ABI);
      let owed_ = await cometReward.connect(signer).callStatic.getRewardOwed(market, dsaWallet0.address);
      let amt: number = owed_.owed;
      console.log(new BigNumber(amt).toFixed(0));
      const spells = [
        {
          connector: connector_,
          method: "claimRewards",
          args: [market, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(new BigNumber(await rewardInterface.connect(signer).balanceOf(dsaWallet0.address)).toFixed(0)).to.be.gte(
        amt
      );
    });

    it("Should supply USDC in Compound V3 through dsaWallet0", async function () {
      const amount = ethers.utils.parseUnits("100", 6); // 1 ETH
      const spells = [
        {
          connector: "COMPOUND-V3-TEST-A",
          method: "deposit",
          args: [market, base, amount, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(new BigNumber(await baseContract.connect(signer).balanceOf(dsaWallet0.address)).toFixed(0)).to.be.lte(
        ethers.utils.parseUnits("0", 6)
      );
      expect(new BigNumber(await comet.connect(signer).balanceOf(dsaWallet0.address)).toFixed(0)).to.be.gte(
        ethers.utils.parseUnits("499", 6)
      );
    });

    it("Should claim rewards to dsa1", async function () {
      let reward = (await cometReward.connect(signer).rewardConfig(market)).token;
      let rewardInterface = new ethers.Contract(reward, ABI);
      let owed_ = await cometReward.connect(signer).callStatic.getRewardOwed(market, dsaWallet0.address);
      let amt: number = owed_.owed;

      const spells = [
        {
          connector: connector_,
          method: "claimRewardsOnBehalfOf",
          args: [market, dsaWallet0.address, dsaWallet1.address, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(new BigNumber(await rewardInterface.connect(signer).balanceOf(dsaWallet1.address)).toFixed(0)).to.be.gte(
        amt
      );
    });

    it("should allow manager for dsaWallet0's collateral and base", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "toggleAccountManager",
          args: [market, dsaWallet1.address, true]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
    });

    it("Should claim rewards to dsa1 using manager", async function () {
      let reward = (await cometReward.connect(signer).rewardConfig(market)).token;
      let rewardInterface = new ethers.Contract(reward, ABI);
      let owed_ = await cometReward.connect(signer).callStatic.getRewardOwed(market, dsaWallet0.address);
      let amt: number = owed_.owed;

      const spells = [
        {
          connector: connector_,
          method: "claimRewardsOnBehalfOf",
          args: [market, dsaWallet0.address, dsaWallet1.address, 0]
        }
      ];

      const tx = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(new BigNumber(await rewardInterface.connect(signer).balanceOf(dsaWallet1.address)).toFixed(0)).to.be.gte(
        amt
      );
    });
  });
});
