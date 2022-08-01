import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { ConnectV2EulerIncentives, ConnectV2EulerIncentives__factory } from "../../../typechain";
import hre from "hardhat";

describe("Euler Rewards Claim Test", () => {
  let signer: SignerWithAddress;
  let signer_user: any;
  const user = "0x9F60699cE23f1Ab86Ec3e095b477Ff79d4f409AD";
  const EUL = "0xd9Fcd98c322942075A5C3860693e9f4f03AAE07b";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Euler Functions", () => {
    let contract: ConnectV2EulerIncentives;

    before(async () => {
      await hre.network.provider.request({
        method: "hardhat_reset",
        params: [
          {
            forking: {
              // eslint-disable-next-line @typescript-eslint/ban-ts-comment
              // @ts-ignore
              jsonRpcUrl: hre.config.networks.hardhat.forking.url,
              blockNumber: 15247044,
            },
          },
        ],
      });

      const deployer = new ConnectV2EulerIncentives__factory(signer);
      contract = await deployer.deploy();
      await contract.deployed();
      console.log("Contract deployed at: ", contract.address);

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [user],
    })

    signer_user = await ethers.getSigner(user)
    });

    it("Returns the positions on Euler", async () => {
        let response = await contract
            .connect(signer_user)
            .claim(
                user, 
                EUL, 
                "459635735326895",
                ["0x7289f1c53c25e201538b91f7f6582388677bd6ff2fca03082267dbb1d96258ac",
                '0xc85ccc67cd68d38b0da6eec50c3c897757832450e22ca103543589fb610b79ee',
                '0x7e57faa32389a498f27187bc1c8ebb993a2065f019e3840cf36d599866ea5504',
                '0x38aae0a5be3e76eef383cc55c48d029acb1c6c4ed91c8385a501c1cc8c2031ca',
                '0x8bfd0363720bf2e5671b2689adbf667b74e47be7a5e91d36c3bdb24e4abad4f4',
                '0xc23081eb1f3001535376d454a070abd67a27de6f3db68089568cf981adeb480f',
                '0x8356b1a7033ff341b75749de37aab0d3a6a9420f20c03b9e07d0f7d3d1840753',
                '0x4300ab0ed87f84baa140f31113e2eee8d20dea7d7ff7848cf6806ecd8067b1c9',
                '0x83248015245f51e6d42021617415097cde157288d1c1de17f4de5fcbbd97b70e',
                '0x785649546b18cad99c2aea8d889689b5b2d4fabc15e6a9ea1ff2b9310beebc44',
                '0x310fdf199874bf9f992c02125278b4592bec5cd5ad1ee30fac130fa2b9ffc0ae',
                '0x6d0a8568a994d5b8a356cf1a933ff8f5c195ea72f0f213f38a08ff3d87b3c4da'
                ],
                "0"
            )
        console.log(response);
    });
  });
});
