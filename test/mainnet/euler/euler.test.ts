import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2Euler__factory, IERC20__factory } from "../../../typechain";
import { parseEther, parseUnits } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { tokens } from "../../../scripts/tests/mainnet/tokens";
const { ethers } = hre;
import type { Signer, Contract } from "ethers";

describe("Euler", function () {
  const connectorName = "EULER-TEST-A";
  let connector: any;

  let wallet0: Signer, wallet1:Signer;
  let dsaWallet0: any;
  let instaConnectorsV2: Contract;
  let masterSigner: Signer;

  const USDC = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'
  const ACC_USDC = '0xe78388b4ce79068e89bf8aa7f218ef6b9ab0e9d0'
  const Usdc = parseUnits('5000', 6)

  const DAI = '0x6b175474e89094c44da98b954eedeac495271d0f'
  const ACC_DAI = '0xcd6Eb888e76450eF584E8B51bB73c76ffBa21FF2'
  const Dai = parseUnits('5000', 18)

  const WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
  const ACC_WETH = '0x05547D4e1A2191B91510Ea7fA8555a2788C70030'
  const Weth = parseUnits('50', 18)

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 15078000,
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
      contractArtifact: ConnectV2Euler__factory,
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

    it("Deposit ETH into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: parseEther("10"),
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        parseEther("10")
      );
    });

    it("Deposit USDC into DSA wallet", async function () {
      const token_usdc = new ethers.Contract(
          USDC,
          IERC20__factory.abi,
          ethers.provider,
      )

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
        parseUnits('5000', 6)
      );
    });

    it("Deposit DAI into DSA wallet", async function () {
      const token_dai = new ethers.Contract(
        DAI,
        IERC20__factory.abi,
        ethers.provider,
      )

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
        parseUnits('5000', 18)
      );
    });

    it("Deposit WETH into DSA wallet", async function () {
      const token_weth = new ethers.Contract(
        WETH,
        IERC20__factory.abi,
        ethers.provider,
      )

      await hre.network.provider.request({
          method: 'hardhat_impersonateAccount',
          params: [ACC_WETH],
      })

      const signer_weth = await ethers.getSigner(ACC_WETH)
      await token_weth.connect(signer_weth).transfer(wallet0.getAddress(), Weth)

      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [ACC_WETH],
      })

      await token_weth.connect(wallet0).transfer(dsaWallet0.address, Weth);

      expect(await token_weth.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(
        parseUnits('50', 18)
      );
    });
  });

  describe("Main", function () {
    beforeEach(async function () {
        const spells = [
          {
            connector: connectorName,
            method: "deposit",
            args: ["0", tokens.usdc.address, "10000000", "true", "0", "0"],
          },
        ];

        const tx = await dsaWallet0
            .connect(wallet0)
            .cast(...encodeSpells(spells), wallet1.getAddress());

        await tx.wait();
    });
    it("Should borrow DAI into DSA wallet", async function () {
        const spells = [
          {
            connector: connectorName,
            method: "borrow",
            args: ["0", tokens.dai.address, "1000000000000000000", "0", "0"],
          },
        ];

        const tx = await dsaWallet0
            .connect(wallet0)
            .cast(...encodeSpells(spells), wallet1.getAddress());

        await tx.wait();
        expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
          parseUnits('1', 18)
        );
    })
    it("Should repay DAI", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "repay",
          args: ["0", tokens.dai.address, "1000000000000000", "0", "0"],
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        parseUnits('5000', 18)
      );
    })

    it("Should withdraw USDC into DSA wallet", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: ["0", tokens.usdc.address, "2000000", "0", "0"],
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
    })

    it("Should eTransfer to subAccount 2", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "eTransfer",
          args: ["0", "1", tokens.usdc.address, "1000000", "0", "0"],
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
    })

    it("Should dTransfer to subAccount 2", async function () {
      const spell = [
        {
          connector: connectorName,
          method: "deposit",
          args: ["1", tokens.usdc.address, "10000000", "true", "0", "0"],
        },
      ];

      const txn = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spell), wallet1.getAddress());

      await txn.wait();

      const spells = [
        {
          connector: connectorName,
          method: "dTransfer",
          args: ["0", "1", tokens.dai.address, "100000000000000000", "0", "0"],
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
    })

    it("Should give debt transfer allowance", async function () {
      const spell = [
        {
          connector: connectorName,
          method: "approveDebt",
          args: ["0", "0x9F60699cE23f1Ab86Ec3e095b477Ff79d4f409AD", tokens.dai.address, "10000000", "0", "0"],
        },
      ];

      const txn = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spell), wallet1.getAddress());

      await txn.wait();
    })

    it("Should enter the market", async function () {
      const spell = [
        {
          connector: connectorName,
          method: "enterMarket",
          args: ["0", [tokens.weth.address]],
        },
      ];

      const txn = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spell), wallet1.getAddress());

      await txn.wait();
    });

    it("Should exit the market", async function () {
      const spell = [
        {
          connector: connectorName,
          method: "exitMarket",
          args: ["0", tokens.weth.address],
        },
      ];

      const txn = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spell), wallet1.getAddress());

      await txn.wait();
    });

    it("Should mint", async function () {

      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: ["2", tokens.weth.address, "1000000000000000000", "true", "0", "0"],
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      const spell = [
        {
          connector: connectorName,
          method: "mint",
          args: ["2", tokens.weth.address, "100000000", "0", "0"],
        },
      ];

      const txn = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spell), wallet1.getAddress());

      await txn.wait();
    })

    it("Should burn", async function () {
      const spell = [
        {
          connector: connectorName,
          method: "burn",
          args: ["2", tokens.weth.address, "10000000", "0", "0"],
        },
      ];

      const txn = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spell), wallet1.getAddress());

      await txn.wait();
    })
  });
});
