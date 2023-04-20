import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { ConnectV2ArbitrumAirdrop, ConnectV2ArbitrumAirdrop__factory } from "../../../typechain";
import hre from "hardhat";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/arbitrum/addresses";
import { abis } from "../../../scripts/constant/abis";

describe("Arbitrum Airdrop Claim Test", () => {
  let signer: SignerWithAddress;
  let signer_user: any;
  const user = "0x30c3D961a21c2352A6FfAfFd4e8cB8730Bf82757";
  const connectorName = "arbitrum-airdrop";
  let dsaWallet0: any;

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Arbitrum Airdrop Functions", () => {
    let contract: ConnectV2ArbitrumAirdrop;

    before(async () => {
      await hre.network.provider.request({
        method: "hardhat_reset",
        params: [
          {
            forking: {
              //@ts-ignore
              jsonRpcUrl: hre.config.networks.hardhat.forking.url,
              blockNumber: 70606643,
            },
          },
        ],
      });

      const deployer = new ConnectV2ArbitrumAirdrop__factory(signer);
      contract = await deployer.deploy();
      await contract.deployed();
      console.log("Contract deployed at: ", contract.address);

      await deployAndEnableConnector({
        connectorName,
        contractArtifact: ConnectV2ArbitrumAirdrop__factory,
        signer: signer,
        connectors: await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2),
      });

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [user],
      });

      signer_user = await ethers.getSigner(user);
      dsaWallet0 = await buildDSAv2(user);
    });

    it("Claims Arbitrum Airdrop and checks claimable tokens", async () => {
      const claimableBefore = await contract.claimableArbTokens(user);
      console.log("Claimable tokens before: ", claimableBefore.toString());

      const spells = [
        {
          connector: connectorName,
          method: "claimAirdrop",
          args: ["0"],
        },
      ];

      const tx = await dsaWallet0.connect(signer_user).cast(...encodeSpells(spells), user);
      await tx.wait();

      const claimableAfter = await contract.claimableArbTokens(user);
      console.log("Claimable tokens after: ", claimableAfter.toString());
    });
  });
});