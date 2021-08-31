const { expect } = require("chai");
const hre = require("hardhat");
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle

const deployAndEnableConnector = require("../../scripts/deployAndEnableConnector.js")
const buildDSAv2 = require("../../scripts/buildDSAv2")
const encodeSpells = require("../../scripts/encodeSpells.js")
const getMasterSigner = require("../../scripts/getMasterSigner")

const addresses = require("../../scripts/constant/addresses");
const abis = require("../../scripts/constant/abis");
const constants = require("../../scripts/constant/constant");
const tokens = require("../../scripts/constant/tokens");

const connectV2BasicERC721Artifacts = require("../../artifacts/contracts/mainnet/connectors/basic-ERC721/main.sol/ConnectV2BasicERC721.json")
const erc721Artifacts = require("../../artifacts/@openzeppelin/contracts/token/ERC721/IERC721.sol/IERC721.json")

const TOKEN_CONTRACT_ADDR = "0x4d695c615a7aacf2d7b9c481b66045bb2457dfde";
const TOKEN_OWNER_ADDR = "0x8c6b10d42ff08e56133fca0dac75e1931b1fcc23";
const TOKEN_ID = "38";

describe("BASIC-ERC721", function () {
    const connectorName = "BASIC-ERC721-A"

    let dsaWallet0
    let masterSigner;
    let instaConnectorsV2;
    let connector;
    let nftContract;
    let tokenOwner;


    const wallets = provider.getWallets()
    const [wallet0, wallet1, wallet2, wallet3] = wallets
    before(async () => {
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [TOKEN_OWNER_ADDR],
        });

        await network.provider.send("hardhat_setBalance", [
            TOKEN_OWNER_ADDR,
            "0x1000000000000000",
        ]);

        // get tokenOwner
        tokenOwner = await ethers.getSigner(
            TOKEN_OWNER_ADDR
        );
        nftContract = await ethers.getContractAt(erc721Artifacts.abi, TOKEN_CONTRACT_ADDR)
        masterSigner = await getMasterSigner(wallet3)
        instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
        connector = await deployAndEnableConnector({
            connectorName,
            contractArtifact: connectV2BasicERC721Artifacts,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })
        console.log("Connector address", connector.address)
    })

    it("Should have contracts deployed.", async function () {
        expect(!!instaConnectorsV2.address).to.be.true;
        expect(!!connector.address).to.be.true;
        expect(!!masterSigner.address).to.be.true;
    });

    describe("DSA wallet setup", function () {
        it("Should build DSA v2", async function () {
            dsaWallet0 = await buildDSAv2(tokenOwner.address)
            expect(!!dsaWallet0.address).to.be.true;
        });

        it("Deposit ETH into DSA wallet", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
        });
    });

    describe("Main", function () {
        it("should deposit successfully", async () => {
            console.log("DSA wallet address", dsaWallet0.address)
            await nftContract.connect(tokenOwner).setApprovalForAll(dsaWallet0.address, true);
            const spells = [
                {
                    connector: connectorName,
                    method: "depositERC721",
                    args: [
                        TOKEN_CONTRACT_ADDR,
                        TOKEN_ID,
                        "0",
                        "0"
                    ]
                }
            ];

            const tx = await dsaWallet0
                .connect(tokenOwner)
                .cast(...encodeSpells(spells), tokenOwner.address);
            const receipt = await tx.wait();
        });
    })
})
