import { expect } from "chai"
import hre from "hardhat"
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle
import { abi } from "../../../scripts/constant/abi/core/InstaImplementations.json"

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector"
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2"
import { encodeSpells } from "../../../scripts/tests/encodeSpells"
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner"
import { addresses } from "../../../scripts/tests/mainnet/addresses"
import { abis } from "../../../scripts/constant/abis"
import type { Signer, Contract } from "ethers";

import { ConnectV2BasicERC1155__factory, IERC1155__factory } from "../../../typechain";

const TOKEN_CONTRACT_ADDR = "0x1ca3262009b21F944e6b92a2a88D039D06F1acFa";
const TOKEN_OWNER_ADDR = "0x1ca3262009b21F944e6b92a2a88D039D06F1acFa";
const TOKEN_ID = "1";

const implementationsMappingAddr = "0xCBA828153d3a85b30B5b912e1f2daCac5816aE9D"

describe("BASIC-ERC1155", function () {
    const connectorName = "BASIC-ERC1155-A"

    let dsaWallet0: any;
    let masterSigner: Signer;
    let instaConnectorsV2: Contract;
    let connector: Contract;
    let nftContract: Contract;
    let tokenOwner: any;
    let instaImplementationsMapping: any;
    let InstaAccountV2DefaultImpl: any;
    let instaAccountV2DefaultImpl: any;


    const wallets = provider.getWallets()
    const [wallet0, wallet1, wallet2, wallet3] = wallets
    before(async () => {
        await hre.network.provider.request({
            method: "hardhat_reset",
            params: [
                {
                    forking: {
                         // @ts-ignore
                        jsonRpcUrl: hre.config.networks.hardhat.forking.url,
                        blockNumber: 13300000,
                    },
                },
            ],
        });
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [TOKEN_OWNER_ADDR],
        });

        await hre.network.provider.send("hardhat_setBalance", [
            TOKEN_OWNER_ADDR,
            "0x10000000000000000",
        ]);
        // get tokenOwner
        tokenOwner = await ethers.getSigner(
            TOKEN_OWNER_ADDR
        );
        nftContract = await ethers.getContractAt(IERC1155__factory.abi, TOKEN_CONTRACT_ADDR)
        masterSigner = await getMasterSigner()
        instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);

        instaImplementationsMapping = await ethers.getContractAt(abi, implementationsMappingAddr);
        InstaAccountV2DefaultImpl = await ethers.getContractFactory("InstaDefaultImplementation")
        instaAccountV2DefaultImpl = await InstaAccountV2DefaultImpl.deploy(addresses.core.instaIndex);
        await instaAccountV2DefaultImpl.deployed()
        connector = await deployAndEnableConnector({
            connectorName,
            contractArtifact: ConnectV2BasicERC1155__factory,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })
        console.log("Connector address", connector.address)
    })

    it("Should have contracts deployed.", async function () {
        expect(!!instaConnectorsV2.address).to.be.true;
        expect(!!connector.address).to.be.true;
        expect(!!(await masterSigner.getAddress())).to.be.true;
    });

    describe("Implementations", function () {
        it("Should add default implementation to mapping.", async function () {
            const tx = await instaImplementationsMapping.connect(masterSigner).setDefaultImplementation(instaAccountV2DefaultImpl.address);
            await tx.wait()
            expect(await instaImplementationsMapping.defaultImplementation()).to.be.equal(instaAccountV2DefaultImpl.address);
        });
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
                    method: "depositERC1155",
                    args: [
                        TOKEN_CONTRACT_ADDR,
                        TOKEN_ID,
                        1,
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
