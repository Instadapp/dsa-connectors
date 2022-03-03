const { expect, should } = require("chai");
const { ethers } = require('hardhat');
const { buildDSAv2 } = require("../../../scripts/tests/buildDSAv2");
const { cEthAddress, cDaiAddress, daiAddress, comptrollerAddress } = require("./constants.js");
const cEthAbi = require("./ABIs/cEthAbi");
const cDaiAbi = require("./ABIs/cDaiAbi");
const comptrollerAbi = require("./ABIs/comptrollerAbi");
const { parseEther, parseUnits } = require("ethers/lib/utils");
const { encodeSpells } = require("../../../scripts/tests/encodeSpells");
const encodeFlashcastData = require("../../../scripts/tests/encodeFlashcastData").default;


describe('Import Compound', function () {
    const connectorName = "IMPORT-COMPOUND-TEST-A"
    let owner; // signers
    let cEth, cDai, comptroller, Dai; // contracts

    before(async () => {
        // create (reset) mainnet fork
        await hre.network.provider.request({
            method: "hardhat_reset",
            params: [
                {
                    forking: {
                        jsonRpcUrl: hre.config.networks.hardhat.forking.url,
                        blockNumber: 13300000,
                    },
                },
            ],
        });

        // get an account
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: ["0x10a25c6886AE02fde87C5561CDD331d941d0771a"],
        });
        owner = await ethers.getSigner("0x10a25c6886AE02fde87C5561CDD331d941d0771a");

        await hre.network.provider.send("hardhat_setBalance", [
            "0x10a25c6886AE02fde87C5561CDD331d941d0771a",
            parseEther('100000').toHexString()
        ]);

        // deploy connector contract
        const contractConnectorFactory = await ethers.getContractFactory("ConnectV2CompoundImport");
        importCompoundConnector = await contractConnectorFactory.connect(owner).deploy();
        console.log("Connector address", importCompoundConnector.address);

        cEth = new ethers.Contract(cEthAddress, cEthAbi, ethers.provider);
        cDai = new ethers.Contract(cDaiAddress, cDaiAbi, ethers.provider);
        const tokenArtifact = await artifacts.readArtifact("@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20");
        Dai = new ethers.Contract(daiAddress, tokenArtifact.abi, ethers.provider);
        comptroller = new ethers.Contract(comptrollerAddress, comptrollerAbi, ethers.provider);

        // deposit ether to Compound
        await cEth.connect(owner).mint({
            value: parseEther('10')
        });

        // enter markets with deposits
        const cTokens = [cEth.address];
        await comptroller.connect(owner).enterMarkets(cTokens);

        // borrow dai from Compound
        await cDai.connect(owner).borrow(parseUnits('1000'));
    });

    describe('Deployment', async () => {
        it('Should set correct name', async () => {
            await expect(await importCompoundConnector.name()).to.eq('Compound-Import-v2');
        });
    });

    describe("DSA wallet setup", async () => {
        it("Should build DSA v2", async () => {
            dsaWallet0 = await buildDSAv2(owner.address);
            console.log(dsaWallet0.address);
            expect(!!dsaWallet0.address).to.be.true;
        });
    });

    describe('Compound position migration', async () => {
        it('Should migrate Compound position', async () => {
            const flashSpells = [
                {
                    connector: 'INSTAPOOL-C',
                    method: 'flashPayback',
                    args: [Dai.address, parseUnits('1000.9'), 0, 0],
                }]

            const spells = [
                {
                    connector: 'INSTAPOOL-A',
                    method: "flashBorrowAndCast",
                    args: [Dai.address, '1000', 1, encodeFlashcastData(flashSpells), bytes(0)]
                }
            ]

            const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
            const receipt = await tx.wait();
        })
        // it('DSA wallet should persist', async () => {
        //     console.log(dsaWallet0.address);
        // });
        // take flash loan of dai through spell
        // call contract function
        // repay flash loan of dai
        // check if import was successful
    })
});


// deploy the connector on mainnet fork
// build a new dsa in tests

// create a Compound position
    // deposit some ether in Compound
    // borrow some DAI

// migrate the Compound position
    // cast the migrate spell

// check if migration was successful
    // check the balance of DSA contract address in ERC20 tokens
