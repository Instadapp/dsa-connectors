const { ethers, network } = require("hardhat");
const chai = require("chai");
const chaiPromise = require("chai-as-promised");
const { solidity } = require("ethereum-waffle");

chai.use(chaiPromise);
chai.use(solidity);

const { expect } = chai;

const getAccessControl = (address, signer) => {
  return ethers.getContractAt("InstaAccessControl", address, signer);
};

describe("Test InstaAccessControl contract", () => {
  let account, instaMaster;
  let accessControlAddress;
  let masterAccessControl;
  const indexInterfaceAddress = "0x2971AdFa57b20E5a416aE5a708A8655A9c74f723";
  const TEST_ROLE = ethers.utils.formatBytes32String("test");

  before("get signers", async () => {
    [account] = await ethers.getSigners();

    const IndexContract = await ethers.getContractAt(
      "contracts/mapping/InstaAccessControl.sol:IndexInterface",
      indexInterfaceAddress
    );
    const masterAddress = await IndexContract.master();

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [masterAddress],
    });

    instaMaster = await ethers.getSigner(masterAddress);
  });

  after(async () => {
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [instaMaster.address],
    });
  });

  beforeEach("deploy contract", async () => {
    const accessControlFactory = await ethers.getContractFactory(
      "InstaAccessControl"
    );
    const accessControl = await accessControlFactory.deploy();

    await accessControl.deployed();
    accessControlAddress = accessControl.address;

    masterAccessControl = await getAccessControl(
      accessControlAddress,
      instaMaster
    );
  });

  it("grant,revoke role should fail with non master signer", async () => {
    const selfAccessControl = await getAccessControl(
      accessControlAddress,
      account
    );

    await expect(
      selfAccessControl.grantRole(TEST_ROLE, account.address)
    ).to.rejectedWith(/AccessControl: sender must be master/);

    await expect(
      selfAccessControl.revokeRole(TEST_ROLE, account.address)
    ).to.rejectedWith(/AccessControl: sender must be master/);
  });

  it("hasRole should return false for roles not assigned to users", async () => {
    expect(await masterAccessControl.hasRole(TEST_ROLE, account.address)).to.eq(
      false
    );
  });

  it("should grant roles", async () => {
    await expect(masterAccessControl.grantRole(TEST_ROLE, account.address))
      .to.emit(masterAccessControl, "RoleGranted")
      .withArgs(TEST_ROLE, account.address);

    expect(await masterAccessControl.hasRole(TEST_ROLE, account.address)).to.eq(
      true
    );
  });

  it("should revoke role", async () => {
    // add a role first
    await masterAccessControl.grantRole(TEST_ROLE, account.address);
    expect(await masterAccessControl.hasRole(TEST_ROLE, account.address)).to.eq(
      true
    );

    // then remove the role
    await expect(masterAccessControl.revokeRole(TEST_ROLE, account.address))
      .to.emit(masterAccessControl, "RoleRevoked")
      .withArgs(TEST_ROLE, account.address, instaMaster.address);

    expect(await masterAccessControl.hasRole(TEST_ROLE, account.address)).to.eq(
      false
    );
  });

  it("should renounce role only with the account not master", async () => {
    // add a role first
    await masterAccessControl.grantRole(TEST_ROLE, account.address);
    expect(await masterAccessControl.hasRole(TEST_ROLE, account.address)).to.eq(
      true
    );

    // then renounce the the role
    await expect(
      masterAccessControl.renounceRole(TEST_ROLE, account.address)
    ).to.rejectedWith(/AccessControl: can only renounce roles for self/);

    const selfAccessControl = await getAccessControl(
      accessControlAddress,
      account
    );
    expect(await selfAccessControl.renounceRole(TEST_ROLE, account.address))
      .to.emit(masterAccessControl, "RoleRevoked")
      .withArgs(TEST_ROLE, account.address, account.address);

    expect(await masterAccessControl.hasRole(TEST_ROLE, account.address)).to.eq(
      false
    );
  });
});
