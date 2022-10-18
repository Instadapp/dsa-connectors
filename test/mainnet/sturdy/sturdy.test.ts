import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2Sturdy, ConnectV2Sturdy__factory } from "../../../typechain";
import { parseEther } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { tokens } from "../../../scripts/tests/mainnet/tokens";
import { constants } from "../../../scripts/constant/constant";
import { addLiquidity } from "../../../scripts/tests/addLiquidity";
import {impersonateAccounts} from "../../../scripts/tests/impersonate";
const { ethers } = hre;
import type { Signer, Contract } from "ethers";

describe("Sturdy", function () {
  const connectorName = "STURDY-TEST-A";
  let connector: any;

  let wallet0: Signer, wallet1:Signer;
  let dsaWallet0: any;
  let instaConnectorsV2: Contract;
  let masterSigner: Signer;

  const stETH = '0xDFe66B14D37C77F4E9b180cEb433d1b164f0281D';
  const crvFRAX = '0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC';

  const dsaDeposit = async (tokenName: string, address: string, amt: string) => {
    const abi = ["function transfer(address to, uint value)"];

    const tokenMapping = {
      dai: {
        impersonateSigner: '0x5d38b4e4783e34e2301a2a36c39a03c45798c4dd',
        address: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
      },
      usdc: {
        impersonateSigner: '0x72a53cdbbcc1b9efa39c834a540550e23463aacb',
        address: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
      },
      usdt: {
        impersonateSigner: '0x5a52e96bacdabb82fd05763e25335261b270efcb',
        address: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
      },
      stETH: {
        impersonateSigner: '0x3c79d7e8a5d6b49336f0fd2f3adde745954bc9f7',
        address: stETH,
      },
      crvFRAX: {
        impersonateSigner: '0xfd1d36995d76c0f75bbe4637c84c06e4a68bbb3a',
        address: crvFRAX,
      }
    };

    const token = tokenMapping[tokenName];
    const [impersonatedSigner] = await impersonateAccounts([token.impersonateSigner]);
    const contract = new ethers.Contract(token.address, abi, impersonatedSigner);

    const tx = await contract.transfer(address, amt);
    await tx.wait();
  };

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 15454171,
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
      contractArtifact: ConnectV2Sturdy__factory,
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
  });

  describe("Main", function () {
    it("should deposit DAI in Sturdy", async function () {
      const amt = parseEther("100"); // 100 dai
      await dsaDeposit("dai", dsaWallet0.address, amt.toString());
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [tokens.dai.address, amt, 0, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
    });
    // it("should provide stETH in Sturdy", async function () {
    //   const amt = parseEther("100");
    //   await dsaDeposit("stETH", dsaWallet0.address, amt.toString());
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "depositCollateral",
    //       args: [stETH, amt, 0, 0],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   await tx.wait();
    // });
    it("should provide crvFRAX in Sturdy", async function () {
      const amt = parseEther("200");
      await dsaDeposit("crvFRAX", dsaWallet0.address, amt.toString());
      const spells = [
        {
          connector: connectorName,
          method: "depositCollateral",
          args: [crvFRAX, amt, 0, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
    });
    it("Should borrow and repay DAI from Sturdy", async function () {
      const amt = parseEther("100"); // 100 DAI
      const setId = "83478237";
      const spells = [
        {
          connector: connectorName,
          method: "borrow",
          args: [tokens.dai.address, amt, 2, 0, setId],
        },
        {
          connector: connectorName,
          method: "repay",
          args: [tokens.dai.address, amt, 2, setId, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
    });

    it("Should withdraw crvFRAX from Sturdy", async function () {
      const slippage = '100'; // 1%
      const spells = [
        {
          connector: connectorName,
          method: "withdrawCollateral",
          args: [crvFRAX, constants.max_value, slippage, 0, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
    });
  });
});
