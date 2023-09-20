import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2MorphoAaveV3__factory, IERC20Minimal__factory } from "../../../typechain";
import { parseEther, parseUnits } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { dsaMaxValue, tokens } from "../../../scripts/tests/mainnet/tokens";

const { ethers } = hre;
import type { Signer, Contract } from "ethers";

const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const ACC_USDC = "0xe78388b4ce79068e89bf8aa7f218ef6b9ab0e9d0";
const Usdc = parseUnits("5000", 6);

const DAI = "0x6b175474e89094c44da98b954eedeac495271d0f";
const ACC_DAI = "0xcd6Eb888e76450eF584E8B51bB73c76ffBa21FF2";
const Dai = parseUnits("1", 18);

const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

const user = "0x41bc7d0687e6cea57fa26da78379dfdc5627c56d";

const token_usdc = new ethers.Contract(USDC, IERC20Minimal__factory.abi, ethers.provider);

const token_dai = new ethers.Contract(DAI, IERC20Minimal__factory.abi, ethers.provider);

const token_weth = new ethers.Contract(WETH, IERC20Minimal__factory.abi, ethers.provider);

describe("Morpho-Aave-v3", function () {
  const connectorName = "MORPHO-AAVE-V3-TEST-A";
  let connector: any;

  let wallet0: Signer, wallet1: Signer;
  let dsaWallet0: any;
  let dsaWallet1: any;
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
            blockNumber: 17544460
          }
        }
      ]
    });
    [wallet0, wallet1] = await ethers.getSigners();
    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2MorphoAaveV3__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
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
      dsaWallet1 = await buildDSAv2(wallet0.getAddress());
      expect(!!dsaWallet1.address).to.be.true;
    });

    it("Deposit 1000 ETH into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: parseEther("1000")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(parseEther("1000"));
      await wallet0.sendTransaction({
        to: dsaWallet1.address,
        value: parseEther("1000")
      });
      expect(await ethers.provider.getBalance(dsaWallet1.address)).to.be.gte(parseEther("1000"));
    });

    it("Deposit 5000 USDC into DSA wallet", async function () {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [ACC_USDC]
      });

      const signer_usdc = await ethers.getSigner(ACC_USDC);
      await token_usdc.connect(signer_usdc).transfer(wallet0.getAddress(), Usdc);

      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [ACC_USDC]
      });

      await token_usdc.connect(wallet0).transfer(dsaWallet0.address, Usdc);

      expect(await token_usdc.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(parseUnits("5000", 6));
    });
  });

  describe("Main", function () {
    it("Should deposit 10 ETH", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [tokens.eth.address, "10000000000000000000", "0", "0"], // 10 ETH
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

    it("Should deposit 1 ETH with MaxIteration", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "depositWithMaxIterations",
          args: [tokens.eth.address, "1000000000000000000", 5, "0", "0"], // 1 ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        parseUnits('989', 18))
      );
    })

    it("Should deposit 10 ETH on behalf", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "depositOnBehalfWithMaxIterations",
          args: [tokens.eth.address, "10000000000000000000", user, 4, "0", "0"], // 1 ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        parseUnits('979', 18))
      );
    })

    it("Should deposit 1 ETH on behalf with MaxIteration", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "depositOnBehalfWithMaxIterations",
          args: [tokens.eth.address, "1000000000000000000", user, 5, "0", "0"], // 1 ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        parseUnits('978', 18))
      );
    })

    it("Should deposit collateral 2000 USDC", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "depositCollateral",
          args: [tokens.usdc.address, "2000000000", "0", "0"], // 50 USDC
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(await token_usdc.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.lte(
        parseUnits('3000', 6)
      );
    })

    it("Should deposit collateral 2000 USDC on behalf with maxValue", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "depositCollateralOnBehalf",
          args: [tokens.usdc.address, dsaMaxValue, user, "0", "0"], // ~3000 USDC
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(await token_usdc.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.lte(
        parseUnits('1', 6)
      );
    })

    it("Should withdraw 10 ETH", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: [tokens.eth.address, "10000000000000000000", "0", "0"], // 10 ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        parseUnits('978', 18))
      );
    })

    it("Should withdraw on behalf of user with maxValue", async function () {
      let ethBala = await ethers.provider.getBalance(user)
      let wethBala = await token_weth.balanceOf(user)

      const spells = [
        {
          connector: connectorName,
          method: "withdrawOnBehalfWithMaxIterations",
          args: [tokens.eth.address, dsaMaxValue, dsaWallet0.address, user, 4, "0", "0"], // Max ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      ethBala = await ethers.provider.getBalance(user)
      wethBala = await token_weth.balanceOf(user)

    })

    it("Should borrow ETH into DSA", async function () {
        const balanceBefore = await ethers.provider.getBalance(dsaWallet0.address);
        const spells = [
          {
            connector: connectorName,
            method: "borrow",
            args: [tokens.eth.address, "500000000000000000", "0", "0"], // 0.5 WETH
          },
        ];

        const tx = await dsaWallet0
            .connect(wallet0)
            .cast(...encodeSpells(spells), wallet1.getAddress());

        await tx.wait();
        const balanceAfter = await ethers.provider.getBalance(dsaWallet0.address);
        expect((balanceAfter).sub(balanceBefore)).to.be.gte(parseUnits('4.9', 17));
    })

    it("Should borrow ETH into user", async function () {
      const balance = await token_weth.balanceOf(user);
      const spells = [
        {
          connector: connectorName,
          method: "borrowOnBehalfWithMaxIterations",
          args: [tokens.eth.address, "200000000000000000", dsaWallet0.address, user, 4, "0", "0"], // 0.7 WETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect((await token_weth.balanceOf(user)).sub(balance))
        .to.be.eq(parseUnits('2', 17));
    })

    it("Should borrow WETH into wallet1 using iteration", async function () {
      const balance = await token_weth.balanceOf(dsaWallet0.address);
      const spells = [
        {
          connector: connectorName,
          method: "borrowWithMaxIterations",
          args: [tokens.weth.address, "20000000000000000", 10, "0", "0"], // 0.02 WETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect((await token_weth.balanceOf(dsaWallet0.address)).sub(balance))
        .to.be.eq(parseUnits('2', 16));
    })

    it("Test withdrawCollateral ", async function () {
      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [ACC_USDC],
      })

      const signer_usdc = await ethers.getSigner(ACC_USDC)
      await token_usdc.connect(signer_usdc).transfer(dsaWallet0.address, parseUnits('500', 6))

      await hre.network.provider.request({
          method: 'hardhat_stopImpersonatingAccount',
          params: [ACC_USDC],
      })

      expect(await token_usdc.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(
        parseUnits('500', 6)
      );

      const balance = await token_usdc.balanceOf(dsaWallet0.address);

      const spells = [
        {
          connector: connectorName,
          method: "depositCollateral",
          args: [tokens.usdc.address, "20000000", "0", "0"], // 20 USDC
        },
        {
          connector: connectorName,
          method: "withdrawCollateral",
          args: [tokens.usdc.address, "19000000", "0", "0"], // 19 USDC
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

    })

    it("Test withdrawCollateralOnBehalf with maxValue", async function () {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [ACC_USDC]
      });

      const signer_usdc = await ethers.getSigner(ACC_USDC);
      await token_usdc.connect(signer_usdc).transfer(dsaWallet0.address, parseUnits("500", 6));

      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [ACC_USDC]
      });

      expect(await token_usdc.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(parseUnits("500", 6));

      const balance = await token_usdc.balanceOf(dsaWallet0.address);

      let spells = [
        {
          connector: connectorName,
          method: "approveManager",
          args: [dsaWallet0.address, true] // 20 USDC
        },
      ];

      let tx = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();

      spells = [
        {
          connector: connectorName,
          method: "depositCollateralOnBehalf",
          args: [tokens.usdc.address, "20000000", dsaWallet1.address, "0", "0"] // 20 USDC
        },
        {
          connector: connectorName,
          method: "withdrawCollateralOnBehalf",
          args: [tokens.usdc.address, dsaMaxValue, dsaWallet1.address, user, "0", "0"] // 20 USDC
        }
      ];

      tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      expect(await token_usdc.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(parseUnits("499", 6));
      
    });

    it("Test payback with maxValue", async function () {
      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [ACC_USDC],
      })

      const signer_usdc = await ethers.getSigner(ACC_USDC)
      await token_usdc.connect(signer_usdc).transfer(dsaWallet0.address, parseUnits('500', 6))

      await hre.network.provider.request({
          method: 'hardhat_stopImpersonatingAccount',
          params: [ACC_USDC],
      })

      expect(await token_usdc.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(
        parseUnits('500', 6)
      );

      const balance = await token_usdc.balanceOf(dsaWallet0.address);

      const spells = [
        {
          connector: connectorName,
          method: "depositCollateral",
          args: [tokens.usdc.address, "200000000", "0", "0"], // 2 ETH
        },
        {
          connector: connectorName,
          method: "borrow",
          args: [tokens.eth.address, "1000000000000000", "0", "0"], // 20 USDC
        },
        {
          connector: connectorName,
          method: "payback",
          args: [tokens.eth.address, dsaMaxValue, "0", "0"], // 20 USDC
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      expect(await token_usdc.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(
        parseUnits('499', 6)
      );
    })

    it("approve manger", async () => {
      const spells = [
        {
          connector: connectorName,
          method: "approveManager",
          args: [user, true],
        },
      ]
      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
    })
  });
});
