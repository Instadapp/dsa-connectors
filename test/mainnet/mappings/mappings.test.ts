import hre, { ethers, network } from "hardhat";
import chai from "chai";
import chaiPromise from "chai-as-promised";
import { solidity } from "ethereum-waffle";
import type { Signer, Contract } from "ethers";

chai.use(chaiPromise);
chai.use(solidity);

const { expect } = chai;

const getMapping = (address: string, signer: Signer) => {
  return ethers.getContractAt("InstaMappingController", address, signer);
};

describe("Test InstaMapping contract", () => {
  let account: any, instaMaster: any;
  let mappingAddress: any;
  let masterMapping: any;
  const indexInterfaceAddress = "0x2971AdFa57b20E5a416aE5a708A8655A9c74f723";
  const testRoleAddress = "0x2971AdFa57b20E5a416aE5a708A8655A9c74f723";

  before("get signers", async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 12796965,
          },
        },
      ],
    });
    [account] = await ethers.getSigners();

    const IndexContract = await ethers.getContractAt(
      "contracts/mapping/InstaMappingController.sol:IndexInterface",
      indexInterfaceAddress
    );
    const masterAddress = await IndexContract.master();

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [masterAddress],
    });

    await network.provider.send("hardhat_setBalance", [
      masterAddress,
      "0x1000000000000000000000000",
    ]);

    instaMaster = await ethers.getSigner(masterAddress);
  });

  after(async () => {
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [instaMaster.address],
    });
  });

  beforeEach("deploy contract", async () => {
    const mappingFactory = await ethers.getContractFactory(
      "InstaMappingController"
    );
    const mapping = await mappingFactory.deploy();

    await mapping.deployed();
    mappingAddress = mapping.address;

    masterMapping = await getMapping(mappingAddress, instaMaster);
  });

  it("grant,revoke role should fail with non master signer", async () => {
    const selfMapping = await getMapping(mappingAddress, account);

    await expect(
      selfMapping.grantRole(testRoleAddress, account.address)
    ).to.rejectedWith(/MappingController: sender must be master/);

    await expect(
      selfMapping.revokeRole(testRoleAddress, account.address)
    ).to.rejectedWith(/MappingController: sender must be master/);
  });

  it("hasRole should return false for roles not assigned to users", async () => {
    expect(await masterMapping.hasRole(testRoleAddress, account.address)).to.eq(
      false
    );
  });

  it("should grant roles", async () => {
    await expect(masterMapping.grantRole(testRoleAddress, account.address))
      .to.emit(masterMapping, "RoleGranted")
      .withArgs(testRoleAddress, account.address);

    expect(await masterMapping.hasRole(testRoleAddress, account.address)).to.eq(
      true
    );
  });

  it("should revoke role", async () => {
    // add a role first
    await masterMapping.grantRole(testRoleAddress, account.address);
    expect(await masterMapping.hasRole(testRoleAddress, account.address)).to.eq(
      true
    );

    // then remove the role
    await expect(masterMapping.revokeRole(testRoleAddress, account.address))
      .to.emit(masterMapping, "RoleRevoked")
      .withArgs(testRoleAddress, account.address, instaMaster.address);

    expect(await masterMapping.hasRole(testRoleAddress, account.address)).to.eq(
      false
    );
  });

  it("should renounce role only with the account not master", async () => {
    // add a role first
    await masterMapping.grantRole(testRoleAddress, account.address);
    expect(await masterMapping.hasRole(testRoleAddress, account.address)).to.eq(
      true
    );

    // then renounce the the role
    await expect(
      masterMapping.renounceRole(testRoleAddress, account.address)
    ).to.rejectedWith(/MappingController: can only renounce roles for self/);

    const selfMapping = await getMapping(mappingAddress, account);
    expect(await selfMapping.renounceRole(testRoleAddress, account.address))
      .to.emit(masterMapping, "RoleRevoked")
      .withArgs(testRoleAddress, account.address, account.address);

    expect(await masterMapping.hasRole(testRoleAddress, account.address)).to.eq(
      false
    );
  });

  it("should do role count properly", async () => {
    expect(await masterMapping.getRoleMemberCount(testRoleAddress)).to.eq(0);

    await masterMapping.grantRole(testRoleAddress, account.address);

    expect(await masterMapping.getRoleMemberCount(testRoleAddress)).to.eq(1);

    await masterMapping.grantRole(testRoleAddress, instaMaster.address);

    expect(await masterMapping.getRoleMemberCount(testRoleAddress)).to.eq(2);

    await masterMapping.revokeRole(testRoleAddress, instaMaster.address);

    expect(await masterMapping.getRoleMemberCount(testRoleAddress)).to.eq(1);
  });

  it("should get member correctly by index", async () => {
    await expect(
      masterMapping.getRoleMember(testRoleAddress, 0)
    ).to.rejectedWith(/EnumerableSet: index out of bounds/);

    await masterMapping.grantRole(testRoleAddress, account.address);

    expect(await masterMapping.getRoleMember(testRoleAddress, 0)).to.eq(
      account.address
    );

    await masterMapping.grantRole(testRoleAddress, instaMaster.address);

    expect(await masterMapping.getRoleMember(testRoleAddress, 1)).to.eq(
      instaMaster.address
    );

    await masterMapping.revokeRole(testRoleAddress, instaMaster.address);

    await expect(
      masterMapping.getRoleMember(testRoleAddress, 1)
    ).to.rejectedWith(/EnumerableSet: index out of bounds/);
  });
});
