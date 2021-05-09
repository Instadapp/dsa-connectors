const { ethers } = require("hardhat");

describe("Test InstaMapping contract", () => {
    let signer, addressAdmin, fakeAccount;
    let mappingContract;
    const otherContractAddress = "0x514910771af9ca656af840dff83e8264ecf986ca";

    beforeEach("deploy contract", async () => {
        [signer, addressAdmin, fakeAccount] = await ethers.getSigners();

        const mappingContractFactory = await ethers.getContractFactory("InstaMappings");
        mappingContract = await mappingContractFactory.deploy();

        await mappingContract.deployed();
    });

    it("should grant role", async () => {
        const GRANT_ROLE_KEY = 'grantRole(address,address)'
        const HAS_ROLE_KEY = 'hasRole(address,address)';
        await mappingContract[GRANT_ROLE_KEY](otherContractAddress, addressAdmin.address, {
            gasLimit: 12000000
        });

        expect(await mappingContract[HAS_ROLE_KEY](otherContractAddress, addressAdmin.address)).to.eq(true);
    });

});