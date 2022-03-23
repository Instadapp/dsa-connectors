import { expect, should } from "chai";
import hre, { ethers, waffle } from "hardhat";
import type { Signer, Contract } from "ethers";
import { BigNumber } from "bignumber.js";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { abis } from "../../../scripts/constant/abis";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { parseEther, parseUnits } from "ethers/lib/utils";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";

import { ConnectV2CompoundImport__factory, ConnectV2InstaPoolV4__factory } from "../../../typechain";
const { provider } = waffle;

const encodeFlashcastData = require("../../../scripts/tests/encodeFlashcastData").default;
const cEthAddress = "0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5";
const cDaiAddress = "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
const daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const comptrollerAddress = "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B";

describe("Import Compound", function () {
  const connectorName = "COMPOUND-IMPORT-C";
  const account = "0x26eD8119c45E3871df446a13F7Fdc9E2C527DaCD";

  const cEthAbi = [
    {
      constant: false,
      inputs: [],
      name: "mint",
      outputs: [],
      payable: true,
      stateMutability: "payable",
      type: "function",
      signature: "0x1249c58b"
    },
    {
      constant: true,
      inputs: [{ internalType: "address", name: "owner", type: "address" }],
      name: "balanceOf",
      outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
      payable: false,
      stateMutability: "view",
      type: "function"
    },
    {
      constant: false,
      inputs: [],
      name: "exchangeRateCurrent",
      outputs: [{ name: "", type: "uint256" }],
      payable: false,
      stateMutability: "nonpayable",
      type: "function"
    }
  ];

  const cDaiAbi = [
    {
      constant: false,
      inputs: [
        {
          internalType: "uint256",
          name: "borrowAmount",
          type: "uint256"
        }
      ],
      name: "borrow",
      outputs: [
        {
          internalType: "uint256",
          name: "",
          type: "uint256"
        }
      ],
      payable: false,
      stateMutability: "nonpayable",
      type: "function",
      signature: "0xc5ebeaec"
    }
  ];

  const comptrollerAbi = [
    {
      constant: false,
      inputs: [
        {
          internalType: "address[]",
          name: "cTokens",
          type: "address[]"
        }
      ],
      name: "enterMarkets",
      outputs: [
        {
          internalType: "uint256[]",
          name: "",
          type: "uint256[]"
        }
      ],
      payable: false,
      stateMutability: "nonpayable",
      type: "function",
      signature: "0xc2998238"
    }
  ];

  let connector2;
  let cEth: Contract, cDai: Contract, comptroller, Dai: any;
  let owner: any;

  let dsaWallet0: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
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
            blockNumber: 13300000
          }
        }
      ]
    });

    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);

    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2CompoundImport__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
    console.log("Connector address", connector.address);

    connector2 = await deployAndEnableConnector({
      connectorName: "INSTAPOOL-C",
      contractArtifact: ConnectV2InstaPoolV4__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
    console.log("Connector address", connector2.address);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [account]
    });

    await hre.network.provider.send("hardhat_setBalance", [account, ethers.utils.parseEther("100000").toHexString()]);

    owner = await ethers.getSigner(account);

    cEth = new ethers.Contract(cEthAddress, cEthAbi);
    cDai = new ethers.Contract(cDaiAddress, cDaiAbi);
    Dai = new ethers.Contract(daiAddress, abis.basic.erc20);
    comptroller = new ethers.Contract(comptrollerAddress, comptrollerAbi);

    // deposit ether to Compound: ETH-A
    await cEth.connect(owner).mint({
      value: parseEther("9")
    });

    // enter markets with deposits
    const cTokens = [cEth.address];
    await comptroller.connect(owner).enterMarkets(cTokens);

    // borrow dai from Compound: DAI-A
    await cDai.connect(owner).borrow(parseUnits("100"));
  });

  describe("Deployment", async () => {
    it("Should set correct name", async () => {
      expect(await connector.name()).to.eq("Compound-Import-v2");
    });
  });

  describe("checks", async () => {
    it("Should check user COMPOUND position", async () => {
      const ethExchangeRate = (await cEth.connect(owner).callStatic.exchangeRateCurrent()) / 1e28;
      expect(new BigNumber(await cEth.connect(owner).balanceOf(owner.address)).dividedBy(1e8).toFixed(0)).to.eq(
        new BigNumber(9).dividedBy(ethExchangeRate).toFixed(0)
      );
      expect(await Dai.connect(owner).balanceOf(owner.address)).to.eq("100000000000000000000");
    });
  });

  describe("DSA wallet setup", async () => {
    it("Should build DSA v2", async () => {
      dsaWallet0 = await buildDSAv2(owner.address);
      console.log(dsaWallet0.address);
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH into DSA wallet", async function () {
      await owner.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
    });
  });

  describe("Compound position migration", async () => {
    it("Should migrate Compound position", async () => {
      const amount = new BigNumber(ethers.utils.parseEther("100").toString()).multipliedBy(9).dividedBy(1e4);
      const flashSpells = [
        {
          connector: "COMPOUND-IMPORT-C",
          method: "importCompound",
          args: [owner.address, ["ETH-A"], ["DAI-A"], [amount.toString()]]
        },
        {
          connector: "INSTAPOOL-C",
          method: "flashPayback",
          args: [daiAddress, amount, 0, 0]
        }
      ];

      const spells = [
        {
          connector: "INSTAPOOL-C",
          method: "flashBorrowAndCast",
          args: [daiAddress, ethers.utils.parseEther("100"), 0, encodeFlashcastData(flashSpells), "0x"]
        }
      ];
      const tx = await dsaWallet0.connect(owner).cast(...encodeSpells(spells), owner.address);
      const receipt = await tx.wait();
    });
  });
});
