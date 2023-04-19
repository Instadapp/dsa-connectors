import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ConnectV2ArbitrumAirdrop, ConnectV2ArbitrumAirdrop__factory } from "../../../typechain";
import hre, { ethers } from "hardhat";

describe("Arbitrum Airdrop Claim Test", () => {
  let signer: SignerWithAddress;
  let userSigner: SignerWithAddress;
  let signer_user: any;
  const user = "0x30c3D961a21c2352A6FfAfFd4e8cB8730Bf82757";

  describe("Arbitrum Airdrop Functions", () => {
    let contract: ConnectV2ArbitrumAirdrop;

    //@ts-ignore
    console.log('hre.config.networks.hardhat.forking.url: ', hre.config.networks.hardhat.forking.url)

    before(async () => {
      await hre.network.provider.request({
        method: "hardhat_reset",
        params: [
          {
            forking: {
              //@ts-ignore
              jsonRpcUrl: hre.config.networks.hardhat.forking.url,
              blockNumber: 70606643
            }
          }
        ]
      });

      [signer] = await ethers.getSigners();
      console.log("Signer: ", signer.address);

      userSigner = await ethers.getSigner(user);

      const deployer = new ConnectV2ArbitrumAirdrop__factory(signer);
      contract = await deployer.deploy();
      await contract.deployed();
      console.log("Contract deployed at: ", contract.address);

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [user],
      });

      signer_user = await ethers.getSigner(user);
    });

    describe("Arbitrum Arbitrum", async () => {
      it("Claims Arbitrum Airdrop", async () => {
        const response = await contract.connect(signer_user).claimAirdrop("4256");
        console.log('response: ', response);
      });
    })
  });
});