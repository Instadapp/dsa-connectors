import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2MorphoAaveV2__factory, IERC20Minimal__factory } from "../../../typechain";
import { parseEther, parseUnits } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { dsaMaxValue, tokens } from "../../../scripts/tests/mainnet/tokens";
const { ethers } = hre;
import type { Signer, Contract } from "ethers";

const USDC = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'
const ACC_USDC = '0xe78388b4ce79068e89bf8aa7f218ef6b9ab0e9d0'
const Usdc = parseUnits('500', 6)

const DAI = '0x6b175474e89094c44da98b954eedeac495271d0f'
const ACC_DAI = '0xcd6Eb888e76450eF584E8B51bB73c76ffBa21FF2'
const Dai = parseUnits('1', 18)

const user = "0x41bc7d0687e6cea57fa26da78379dfdc5627c56d"

const token_usdc = new ethers.Contract(
  USDC,
  IERC20Minimal__factory.abi,
  ethers.provider,
)

const token_dai = new ethers.Contract(
  DAI,
  IERC20Minimal__factory.abi,
  ethers.provider,
)

describe("Morpho-Aave", function () {
  const connectorName = "MORPHO-AAVE-TEST-A";
  let connector: any;

  let wallet0: Signer, wallet1:Signer;
  let dsaWallet0: any;
  let instaConnectorsV2: Contract;
  let masterSigner: Signer;

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 15714501,
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
      contractArtifact: ConnectV2MorphoAaveV2__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
    console.log("Connector address", connector.address);
  });

  it("should have contracts deployed", async () => {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
      dsaWallet0 = await buildDSAv2(wallet0.getAddress());
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit 1000 ETH into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: parseEther("1000"),
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        parseEther("1000")
      );
    });

    it("Deposit 500 USDC into DSA wallet", async function () {

      await hre.network.provider.request({
          method: 'hardhat_impersonateAccount',
          params: [ACC_USDC],
      })
  
      const signer_usdc = await ethers.getSigner(ACC_USDC)
      await token_usdc.connect(signer_usdc).transfer(wallet0.getAddress(), Usdc)
  
      await hre.network.provider.request({
          method: 'hardhat_stopImpersonatingAccount',
          params: [ACC_USDC],
      })

      await token_usdc.connect(wallet0).transfer(dsaWallet0.address, Usdc);

      expect(await token_usdc.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(
        parseUnits('500', 6)
      );
    });

    it("Deposit 1 DAI into DSA wallet", async function () {

      await hre.network.provider.request({
          method: 'hardhat_impersonateAccount',
          params: [ACC_DAI],
      })

      const signer_dai = await ethers.getSigner(ACC_DAI)
      await token_dai.connect(signer_dai).transfer(wallet0.getAddress(), Dai)

      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [ACC_DAI],
      })

      await token_dai.connect(wallet0).transfer(dsaWallet0.address, Dai);

      expect(await token_dai.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(
        parseUnits('1', 18)
      );
    });
  });

  describe("Main", function () {

    it("Should deposit 10 ETH", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [tokens.eth.address, tokens.eth.aTokenAddress, "10000000000000000000", "0", "0"], // 10 ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        parseUnits('990', 18))
      );
    })

    it("Should deposit 10 USDC", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [tokens.usdc.address, tokens.usdc.aTokenAddress, "10000000", "0", "0"], // 10 USDC
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(await token_usdc.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.lte(
        parseUnits('490', 18)
      );
    })

    it("Should deposit 100 USDC on behalf", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "depositOnBehalf",
          args: [tokens.usdc.address, tokens.usdc.aTokenAddress, user, "100000000", "0", "0"], // 100 USDC
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(await token_usdc.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.lte(
        parseUnits('390', 18)
      );
    })

    it("Should borrow DAI into DSA", async function () {
        const spells = [
          {
            connector: connectorName,
            method: "borrow",
            args: [tokens.dai.address, tokens.dai.aTokenAddress, "10000000000000000000", "0", "0"], // 10 DAI
          },
        ];

        const tx = await dsaWallet0
            .connect(wallet0)
            .cast(...encodeSpells(spells), wallet1.getAddress());

        await tx.wait();
        expect(await token_dai.connect(masterSigner).balanceOf(dsaWallet0.address))
          .to.be.gte(parseUnits('11', 18));
    })

    it("Should payback DAI MAX", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "payback",
          args: [tokens.dai.address, tokens.dai.aTokenAddress, dsaMaxValue, "0", "0"], // Max DAI
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(await token_dai.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.lte(
        parseUnits('1', 18)
      );
    })

    it("Should payback ETH on behalf", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "paybackOnBehalf",
          args: [tokens.eth.address, tokens.eth.aTokenAddress, user, dsaMaxValue, "0", "0"], // Max ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        parseUnits('125', 18)
      );
    })

    it("Should withdraw ETH max", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: [tokens.eth.address, tokens.eth.aTokenAddress, dsaMaxValue, "0", "0"], // Max ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        parseUnits('134', 18))
      );
    })

    it("Should withdraw 8 USDC", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: [tokens.usdc.address, tokens.usdc.aTokenAddress, "8000000", "0", "0"], // 8 USDC
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(expect(await token_usdc.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.gte(
        parseUnits('398', 6))
      );
    })
  });
});
