import { expect } from "chai";
import hre from "hardhat";
const { waffle, ethers } = hre;
const { provider } = waffle;

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addLiquidity } from "../../../scripts/tests/addLiquidity";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2Hop__factory } from "../../../typechain";
import { Signer, Contract } from "ethers";

describe("Hop Connector", function () {
  const connectorName = "HOP-MAINNET-X";

  let dsaWallet0: Contract;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;

  const DAI_ADDR = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
  const l2AmmWrapper = "0x3d4Cc8A61c7528Fd86C55cfe061a78dCBA48EDd1";

  const token = new ethers.Contract(DAI_ADDR, abis.basic.erc20);

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 14854895
          }
        }
      ]
    });

    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2Hop__factory,
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
      dsaWallet0 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH & DAI into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));

      await addLiquidity("dai", dsaWallet0.address, ethers.utils.parseEther("10000"));
    });
  });

  describe("Main", function () {
    it("should migrate DAI from L1 to L2", async function () {
      const amount = ethers.utils.parseEther("10");
      const deadline = Date.now() + 604800;
      const getId = "0";

      const params: any = [DAI_ADDR, wallet0.address, l2AmmWrapper, 137, amount.toString(), "0", deadline];

      const spells = [
        {
          connector: connectorName,
          method: "bridge",
          args: [params, getId]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      let receipt = await tx.wait();
    });

    it("should migrate ETH from L1 to L2", async function () {
      const amount = ethers.utils.parseEther("10");
      const deadline = Date.now() + 604800;
      const getId = "0";

      const params: any = [
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
        wallet0.address,
        "0xb8901acB165ed027E32754E0FFe830802919727f",
        137,
        amount.toString(),
        "0",
        deadline
      ];

      const spells = [
        {
          connector: connectorName,
          method: "bridge",
          args: [params, getId]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      let receipt = await tx.wait();
    });
  });
});
