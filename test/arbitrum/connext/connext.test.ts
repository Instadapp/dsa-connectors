import { expect } from "chai";
import hre from "hardhat";
const { ethers, waffle } = hre;
const { provider } = waffle;

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/arbitrum/addresses";
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2ConnextArbitrum__factory } from "../../../typechain";
import { Signer, Contract } from "ethers";


describe("Connext Connector [Arbitrum]", () => {
  const connectorName = "CONNEXT-TEST-A";

  let dsaWallet0: Contract;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;
  let usdcContract: Contract;
  let signer: any;
  
  const usdcAddr = "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8";
  const ethAddr = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
  const account = "0x62383739d68dd0f844103db8dfb05a7eded5bbe6";

  const wallets = provider.getWallets();
  const [wallet0, wallet1] = wallets;

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 82686991
          }
        }
      ]
    });

    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2ConnextArbitrum__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
    usdcContract = await ethers.getContractAt(abis.basic.erc20, usdcAddr);
    signer = await ethers.getSigner(account);

    await hre.network.provider.send("hardhat_setBalance", [account, ethers.utils.parseEther("10").toHexString()]);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [account]
    });

    await usdcContract.connect(signer).transfer(wallet0.address, ethers.utils.parseUnits("10000", 6));
    console.log("deployed connector: ", connector.address);
  });

  it("Should have contracts deployed.", async () => {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup",  () => {
    it("Should build DSA v2", async () => {
      dsaWallet0 = await buildDSAv2(wallet0.getAddress());
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH & USDC into DSA wallet", async () => {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));

      await usdcContract.connect(wallet0).transfer(dsaWallet0.address, ethers.utils.parseUnits("10", 6));
      expect(await usdcContract.balanceOf(dsaWallet0.address)).to.be.gte(ethers.utils.parseUnits("10", 6));
    });
  });

  describe("Main", () => {
    it("should xcall with eth", async () => {
      const amount = ethers.utils.parseEther("5");
      const domainId = 6648936;
      const slippage = 10000;
      const relayerFee = ethers.utils.parseEther("1");
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
          args: [xcallParams, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
    });

    it("should xcall with usdc", async () => {
      const amount = ethers.utils.parseUnits("5", 6);
      const domainId = 6648936;
      const slippage = 10000;
      const relayerFee = ethers.utils.parseEther("1");
      const callData = "0x";

      const xcallParams: any = [
        domainId,
        wallet1.address,
        usdcAddr,
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
          args: [xcallParams, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
    });
  });
});
