const { ethers, network } = require("hardhat");
const chai = require("chai");
const chaiPromise = require("chai-as-promised");
const { solidity } = require("ethereum-waffle");

chai.use(chaiPromise);
chai.use(solidity);

const { expect } = chai;

const getInstaMappings = (address, signer) => {
  return ethers.getContractAt("InstaMappings", address, signer);
};

describe("Test InstaMapping contract", () => {
  let account, instaMaster;
  let instaMappingAddress;
  let masterInstaMapping;
  const indexInterfaceAddress = "0x2971AdFa57b20E5a416aE5a708A8655A9c74f723";
  const TEST_CONTRACT = "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984";
  let TEST_CONTRACT_ENCODED;
  const keys = {
    grant: "grantRole(address,address)",
    revoke: "revokeRole(address,address)",
    renounce: "renounceRole(address,address)",
    has: "hasRole(address,address)",
  };

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
    const instaMappingFactory = await ethers.getContractFactory(
      "InstaMappings"
    );
    const instaMapping = await instaMappingFactory.deploy();

    await instaMapping.deployed();
    instaMappingAddress = instaMapping.address;

    masterInstaMapping = await getInstaMappings(
      instaMappingAddress,
      instaMaster
    );

    TEST_CONTRACT_ENCODED = await instaMapping.getMappingContractRole(
      TEST_CONTRACT
    );
  });

  it("grant,revoke role should fail with non master signer", async () => {
    const selfInstaMapping = await getInstaMappings(
      instaMappingAddress,
      account
    );

    await expect(
      selfInstaMapping[keys.grant](TEST_CONTRACT, account.address)
    ).to.rejectedWith(/AccessControl: sender must be master/);

    await expect(
      selfInstaMapping[keys.revoke](TEST_CONTRACT, account.address)
    ).to.rejectedWith(/AccessControl: sender must be master/);
  });

  it("hasRole should return false for roles not assigned to users", async () => {
    expect(
      await masterInstaMapping[keys.has](TEST_CONTRACT, account.address)
    ).to.eq(false);
  });

  it("should grant roles", async () => {
    await expect(masterInstaMapping[keys.grant](TEST_CONTRACT, account.address))
      .to.emit(masterInstaMapping, "RoleGranted")
      .withArgs(TEST_CONTRACT_ENCODED, account.address);

    expect(
      await masterInstaMapping[keys.has](TEST_CONTRACT, account.address)
    ).to.eq(true);
  });

  it("should revoke role", async () => {
    // add a role first
    await masterInstaMapping[keys.grant](TEST_CONTRACT, account.address);
    expect(
      await masterInstaMapping[keys.has](TEST_CONTRACT, account.address)
    ).to.eq(true);

    // then remove the role
    await expect(
      masterInstaMapping[keys.revoke](TEST_CONTRACT, account.address)
    )
      .to.emit(masterInstaMapping, "RoleRevoked")
      .withArgs(TEST_CONTRACT_ENCODED, account.address, instaMaster.address);

    expect(
      await masterInstaMapping[keys.has](TEST_CONTRACT, account.address)
    ).to.eq(false);
  });

  it("should renounce role only with the account not master", async () => {
    // add a role first
    await masterInstaMapping[keys.grant](TEST_CONTRACT, account.address);
    expect(
      await masterInstaMapping[keys.has](TEST_CONTRACT, account.address)
    ).to.eq(true);

    // then renounce the the role
    await expect(
      masterInstaMapping[keys.renounce](TEST_CONTRACT, account.address)
    ).to.rejectedWith(/AccessControl: can only renounce roles for self/);

    const selfInstaMapping = await getInstaMappings(
      instaMappingAddress,
      account
    );
    expect(
      await selfInstaMapping[keys.renounce](TEST_CONTRACT, account.address)
    )
      .to.emit(masterInstaMapping, "RoleRevoked")
      .withArgs(TEST_CONTRACT_ENCODED, account.address, account.address);

    expect(
      await masterInstaMapping[keys.has](TEST_CONTRACT, account.address)
    ).to.eq(false);
  });
});
