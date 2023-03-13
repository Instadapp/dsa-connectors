import { expect } from "chai";
import hre from "hardhat";
const { ethers, waffle } = hre;
const { provider, deployContract } = waffle;

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/optimism/addresses";
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2ConnextOptimism__factory } from "../../../typechain";
import { Signer, Contract } from "ethers";

describe("Connext Connector [Optimism]", function () {
  const connectorName = "CONNEXT-TEST-A";

  let dsaWallet0: Contract;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;

  const connextAddr = "0x8f7492DE823025b4CfaAB1D34c58963F2af5DEDA";
  const usdcAddr = "0x7F5c764cBc14f9669B88837ca1490cCa17c31607";
  const ethAddr = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
  const wethAddr = "0x4200000000000000000000000000000000000006";

  const wallets = provider.getWallets();
  const [wallet0, wallet1] = wallets;

  // const usdc = new ethers.Contract(usdcAddr, abis.basic.erc20);
  // const weth = new ethers.Contract(wethAddr, abis.basic.erc20);

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 7093500
          }
        }
      ]
    });

    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2ConnextOptimism__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });

    console.log("Connector address", connector.address);
  });

  it("Should have contracts deployed.", async function () {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
      dsaWallet0 = await buildDSAv2(wallet0.getAddress());
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH & USDC into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));

      // await addLiquidity(
      //   "usdc",
      //   dsaWallet0.address,
      //   ethers.utils.parseEther("100000")
      // );
    });
  });

  describe("Main", function () {
    it("should xcall with eth", async function () {
      const amount = ethers.utils.parseEther("10");
      const domainId = 6648936;
      const slippage = 10000;
      const relayerFee = ethers.utils.parseEther("1");
      const getId = 0;
      const callData = "0x";

      const xcallParams: any = [
        domainId,
        wallet1.address,
        ethAddr,
        wallet1.address,
        amount,
        slippage,
        relayerFee,
        callData
      ];

      const spells = [
        {
          connector: connectorName,
          method: "xcall",
          args: [xcallParams, getId]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
    });
  });
});
