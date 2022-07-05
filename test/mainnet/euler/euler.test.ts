import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2Euler, ConnectV2Euler__factory, IERC20__factory } from "../../../typechain";
import { parseEther } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { tokens } from "../../../scripts/tests/mainnet/tokens";
import { constants } from "../../../scripts/constant/constant";
import { addLiquidity } from "../../../scripts/tests/addLiquidity";
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
  const Usdc = ethers.utils.parseUnits('5000', 6)

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

        await hre.network.provider.request({
            method: 'hardhat_stopImpersonatingAccount',
            params: [ACC_USDC],
        })
        expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
          parseEther("10")
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
            args: ["0", tokens.dai.address, "1000000", "0", "0"],
            },
        ];

        const tx = await dsaWallet0
            .connect(wallet0)
            .cast(...encodeSpells(spells), wallet1.getAddress());

        await tx.wait();
    })
 });
});
