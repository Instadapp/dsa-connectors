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

const connectV2CompoundArtifacts = require("../../artifacts/contracts/mainnet/connectors/compound/main.sol/ConnectV2Compound.json")
const connectV2PoolTogetherArtifacts = require("../../artifacts/contracts/mainnet/connectors/pooltogether/main.sol/ConnectV2PoolTogether.json")
const connectV2UniswapArtifacts = require("../../artifacts/contracts/mainnet/connectors/uniswap/main.sol/ConnectV2UniswapV2.json")

const token = tokens.dai.address // DAI Token

// PoolTogether Address: https://docs.pooltogether.com/resources/networks/ethereum
const prizePool = "0xEBfb47A7ad0FD6e57323C8A42B2E5A6a4F68fc1a" // DAI Prize Pool
const controlledToken = "0x334cBb5858417Aee161B53Ee0D5349cCF54514CF" // PT DAI Ticket
const daiPoolFaucet = "0xF362ce295F2A4eaE4348fFC8cDBCe8d729ccb8Eb"  // DAI POOL Faucet
const poolTokenAddress = "0x0cEC1A9154Ff802e7934Fc916Ed7Ca50bDE6844e"
const tokenFaucetProxyFactory = "0xE4E9cDB3E139D7E8a41172C20b6Ed17b6750f117" // TokenFaucetProxyFactory for claimAll
const daiPod = "0x2f994e2E4F3395649eeE8A89092e63Ca526dA829" // DAI Pod
const uniswapPoolETHLPPrizePool = "0x3AF7072D29Adde20FC7e173a7CB9e45307d2FB0A"   // Uniswap Pool/ETH LP PrizePool
const uniswapPoolETHLPFaucet = "0x9A29401EF1856b669f55Ae5b24505b3B6fAEb370"   // Uniswap Pool/ETH LP Faucet
const uniswapPOOLETHLPToken = "0x85cb0bab616fe88a89a35080516a8928f38b518b"
const ptUniswapPOOLETHLPTicket = "0xeb8928ee92efb06c44d072a24c2bcb993b61e543"
const poolPoolPrizePool = "0x396b4489da692788e327e2e4b2b0459a5ef26791"
const ptPoolTicket = "0x27d22a7648e955e510a40bdb058333e9190d12d4"
const WETHAddress = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"

describe("PoolTogether", function () {
    const connectorName = "COMPOUND-TEST-A"
    const uniswapConnectorName = "UNISWAP-TEST-A"
    const ptConnectorName = "POOLTOGETHER-TEST-A"
    
    let dsaWallet0
    let masterSigner;
    let instaConnectorsV2;
    let connector;
    let ptConnector;
    let uniswapConnector;
    
    const wallets = provider.getWallets()
    const [wallet0, wallet1, wallet2, wallet3] = wallets
    before(async () => {
        masterSigner = await getMasterSigner(wallet3)
        instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);

        // Deploy and enable Compound Connector
        connector = await deployAndEnableConnector({
            connectorName,
            contractArtifact: connectV2CompoundArtifacts,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })

        // Deploy and enable Pool Together Connector
        ptConnector = await deployAndEnableConnector({
            connectorName: ptConnectorName,
            contractArtifact: connectV2PoolTogetherArtifacts,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })

        // Deploy and enable Uniswap Connector
        uniswapConnector = await deployAndEnableConnector({
            connectorName: uniswapConnectorName,
            contractArtifact: connectV2UniswapArtifacts,
            signer: masterSigner,
            connectors: instaConnectorsV2
        })
  })

  it("Should have contracts deployed.", async function () {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!ptConnector.address).to.be.true;
    expect(!!uniswapConnector.address).to.be.true;
    expect(!!masterSigner.address).to.be.true;
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
        dsaWallet0 = await buildDSAv2(wallet0.address)
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

  describe("Main - DAI Prize Pool Test", function () {

    it("Should deposit ETH in Compound", async function () {
        const amount = ethers.utils.parseEther("1") // 1 ETH
        const spells = [
            {
                connector: connectorName,
                method: "deposit",
                args: ["ETH-A", amount, 0, 0]
            }
        ]

        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()
        expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(ethers.utils.parseEther("9"));
    });

    it("Should borrow DAI from Compound and deposit DAI into DAI Prize Pool", async function () {
        const amount = ethers.utils.parseEther("100") // 100 DAI
        const setId = "83478237"
        const spells = [
            {
                connector: connectorName,
                method: "borrow",
                args: ["DAI-A", amount, 0, setId]
            },
            {
                connector: ptConnectorName,
                method: "depositTo",
                args: [prizePool, dsaWallet0.address, amount, controlledToken, constants.address_zero, setId, 0]
            }
        ]
        // Before Spell
        // DAI balance 0
        let daiToken = await ethers.getContractAt(abis.basic.erc20, token)
        let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("Before spell:");
        console.log("\tBalance before: ", daiBalance.toString(), tokens.dai.symbol);

        // PT DAI Ticket balance is 0
        let cToken = await ethers.getContractAt(abis.basic.erc20, controlledToken)
        const balance = await cToken.balanceOf(dsaWallet0.address)
        const tokenName = await cToken.name()
        console.log("\tBalance before: ", balance.toString(), tokenName)

        // Run spell transaction
        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        // After spell
        // Expect DAI balance to equal 0
        daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("After spell:");
        console.log("\tBalance after: ", daiBalance.toString(), tokens.dai.symbol);
        expect(daiBalance).to.be.eq(ethers.utils.parseEther("0"));

        // Expect PT DAI Ticket to equal 100
        const balanceAfter = await cToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", balanceAfter.toString(), tokenName)
        expect(balanceAfter.toString()).to.be.eq(ethers.utils.parseEther("100"));

        expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(ethers.utils.parseEther("9"));
    });

    it("Should wait 11 days, withdraw all PrizePool, get back 100 DAI, and claim POOL", async function () {
        const amount = ethers.utils.parseEther("100") // 100 DAI
        const spells = [
            {
                connector: ptConnectorName,
                method: "withdrawInstantlyFrom",
                args: [prizePool, dsaWallet0.address, amount, controlledToken, amount, 0, 0]
            },
            {
                connector: ptConnectorName,
                method: "claim",
                args: [daiPoolFaucet, dsaWallet0.address, 0]
            }
        ]

        // Before spell
        // DAI balance is 0
        let daiToken = await ethers.getContractAt(abis.basic.erc20, token)
        let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("Before Spell:")
        console.log("\tBalance before: ", daiBalance.toString(), tokens.dai.symbol);

        // PT Dai Ticket is 100
        let cToken = await ethers.getContractAt(abis.basic.erc20, controlledToken)
        const balance = await cToken.balanceOf(dsaWallet0.address)
        const tokenName = await cToken.name()
        console.log("\tBalance before: ", balance.toString(), tokenName)

        // PoolToken is 0
        let poolToken = await ethers.getContractAt(abis.basic.erc20, poolTokenAddress)
        const poolBalance = await poolToken.balanceOf(dsaWallet0.address)
        const poolTokenName = await poolToken.name()
        console.log("\tBalance before: ", poolBalance.toString(), poolTokenName)

        // Increase time by 11 days so we get back all DAI without early withdrawal fee
        await ethers.provider.send("evm_increaseTime", [11*24*60*60]);

        // Run spell transaction
        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        // After spell
        // Expect DAI balance to be equal to 100, because of no early withdrawal fee
        daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("After spell: ");
        console.log("\tBalance after: ", daiBalance.toString(), tokens.dai.symbol);
        expect(daiBalance).to.be.eq(ethers.utils.parseEther("100"));

        // Expect PT Dai Ticket to equal 0
        const balanceAfter = await cToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", balanceAfter.toString(), tokenName)
        expect(balanceAfter.toNumber()).to.be.eq(0);

        // Expect Pool Token Balance to be greater than 0
        const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", poolBalanceAfter.toString(), poolTokenName)
        expect(poolBalanceAfter).to.be.gt(ethers.utils.parseEther("0"));
    });

    it("Should deposit and withdraw all PrizePool, get back less than 100 DAI", async function() {
        const amount = ethers.utils.parseEther("100") // 100 DAI
        const spells = [
            {
                connector: ptConnectorName,
                method: "depositTo",
                args: [prizePool, dsaWallet0.address, amount, controlledToken, constants.address_zero, 0, 0]
            },
            {
                connector: ptConnectorName,
                method: "withdrawInstantlyFrom",
                args: [prizePool, dsaWallet0.address, amount, controlledToken, amount, 0, 0]
            }
        ]

        // Before spell
        // DAI balance is 0
        let daiToken = await ethers.getContractAt(abis.basic.erc20, token)
        let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("Before Spell:")
        console.log("\tBalance before: ", daiBalance.toString(), tokens.dai.symbol);

        // PT Dai Ticket is 100
        let cToken = await ethers.getContractAt(abis.basic.erc20, controlledToken)
        const balance = await cToken.balanceOf(dsaWallet0.address)
        const tokenName = await cToken.name()
        console.log("\tBalance before: ", balance.toString(), tokenName)

        // PoolToken is 0
        let poolToken = await ethers.getContractAt(abis.basic.erc20, poolTokenAddress)
        const poolBalance = await poolToken.balanceOf(dsaWallet0.address)
        const poolTokenName = await poolToken.name()
        console.log("\tBalance before: ", poolBalance.toString(), poolTokenName)

        // Run spell transaction
        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        // After spell
        // Expect DAI balance to be less than 100, because of early withdrawal fee
        daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("After spell: ");
        console.log("\tBalance after: ", daiBalance.toString(), tokens.dai.symbol);
        expect(daiBalance).to.be.lt(ethers.utils.parseEther("100"));

        // Expect PT Dai Ticket to equal 0
        const balanceAfter = await cToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", balanceAfter.toString(), tokenName)
        expect(balanceAfter.toNumber()).to.be.eq(0);

        // Expect Pool Token Balance to greater than 0
        const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", poolBalanceAfter.toString(), poolTokenName)
        expect(poolBalanceAfter).to.be.gt(ethers.utils.parseEther("0"));

    });

    it("Should deposit, wait 11 days, and withdraw all PrizePool, get 99 DAI, and claim all POOL using claimAll", async function() {
        const amount = ethers.utils.parseEther("99") // 99 DAI
        const depositSpells = [
            {
                connector: ptConnectorName,
                method: "depositTo",
                args: [prizePool, dsaWallet0.address, amount, controlledToken, constants.address_zero, 0, 0]
            }
        ]

        const withdrawSpells = [
            {
                connector: ptConnectorName,
                method: "withdrawInstantlyFrom",
                args: [prizePool, dsaWallet0.address, amount, controlledToken, amount, 0, 0]
            },
            {
                connector: ptConnectorName,
                method: "claimAll",
                args: [tokenFaucetProxyFactory, dsaWallet0.address, [daiPoolFaucet]]
            }
        ]

        // Before spell
        // DAI balance is 0
        let daiToken = await ethers.getContractAt(abis.basic.erc20, token)
        let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("Before Spell:")
        console.log("\tBalance before: ", daiBalance.toString(), tokens.dai.symbol);

        // PT Dai Ticket is 0
        let cToken = await ethers.getContractAt(abis.basic.erc20, controlledToken)
        const balance = await cToken.balanceOf(dsaWallet0.address)
        const tokenName = await cToken.name()
        console.log("\tBalance before: ", balance.toString(), tokenName)

        // PoolToken is 0
        let poolToken = await ethers.getContractAt(abis.basic.erc20, poolTokenAddress)
        const poolBalance = await poolToken.balanceOf(dsaWallet0.address)
        const poolTokenName = await poolToken.name()
        console.log("\tBalance before: ", poolBalance.toString(), poolTokenName)

        // Run spell transaction
        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(depositSpells), wallet1.address)
        const receipt = await tx.wait()

        // Increase time by 11 days so we get back all DAI without early withdrawal fee
        await ethers.provider.send("evm_increaseTime", [11*24*60*60]);

        // Run spell transaction
        const tx2 = await dsaWallet0.connect(wallet0).cast(...encodeSpells(withdrawSpells), wallet1.address)
        const receipt2 = await tx2.wait()

        // After spell
        // Expect DAI balance to be 99
        daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("After spell: ");
        console.log("\tBalance after: ", daiBalance.toString(), tokens.dai.symbol);
        expect(daiBalance).to.be.eq(ethers.utils.parseEther("99"));

        // Expect PT Dai Ticket to equal 0
        const balanceAfter = await cToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", balanceAfter.toString(), tokenName)
        expect(balanceAfter.toNumber()).to.be.eq(0);

        // Expect Pool Token Balance to be greateir than 0
        const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", poolBalanceAfter.toString(), poolTokenName)
        expect(poolBalanceAfter).to.be.gt(ethers.utils.parseEther("0"));
    });
  })

  describe("Main - DAI Pod Test", function() {
    it("Should deposit in Pod", async function() {
        const amount = ethers.utils.parseEther("99") // 99 DAI
        const spells = [
            {
                connector: ptConnectorName,
                method: "depositToPod",
                args: [prizePool, daiPod, dsaWallet0.address, amount, 0, 0]
            }
        ]

        // Before spell
        // DAI balance is 99
        let daiToken = await ethers.getContractAt(abis.basic.erc20, token)
        let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("Before Spell:")
        console.log("\tBalance before: ", daiBalance.toString(), tokens.dai.symbol);

        // PoolToken is 0
        let poolToken = await ethers.getContractAt(abis.basic.erc20, poolTokenAddress)
        const poolBalance = await poolToken.balanceOf(dsaWallet0.address)
        const poolTokenName = await poolToken.name()
        console.log("\tBalance before: ", poolBalance.toString(), poolTokenName)

        // PodToken is 0
        let podToken = await ethers.getContractAt(abis.basic.erc20, daiPod)
        const podBalance = await podToken.balanceOf(dsaWallet0.address)
        const podTokenName = await podToken.name()
        console.log("\tBalance before: ", podBalance.toString(), podTokenName)

        // Run spell transaction
        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        // After spell
        // Expect DAI balance to be less than 100, because of early withdrawal fee
        daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("After spell: ");
        console.log("\tBalance after: ", daiBalance.toString(), tokens.dai.symbol);
        expect(daiBalance).to.be.lt(ethers.utils.parseEther("100"));

        // Expect Pool Token Balance to greater than 0
        const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", poolBalanceAfter.toString(), poolTokenName)
        expect(poolBalanceAfter).to.be.gt(ethers.utils.parseEther("0"));

        // Expect Pod Token Balance to greater than 0
        const podBalanceAfter = await podToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", podBalanceAfter.toString(), podTokenName)
        expect(podBalanceAfter).to.be.eq(ethers.utils.parseEther("99"));
    });

    it("Should wait 11 days, withdraw all podTokens, get back 99 DAI", async function () {
        const amount = ethers.utils.parseEther("99") // 99 DAI
        const maxFee = 0;
        const spells = [
            {
                connector: ptConnectorName,
                method: "withdrawFromPod",
                args: [daiPod, amount, maxFee, 0, 0]
            }
        ]

        // Before spell
        // DAI balance is 0
        let daiToken = await ethers.getContractAt(abis.basic.erc20, token)
        let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("Before Spell:")
        console.log("\tBalance before: ", daiBalance.toString(), tokens.dai.symbol);

        // PoolToken is 0
        let poolToken = await ethers.getContractAt(abis.basic.erc20, poolTokenAddress)
        const poolBalance = await poolToken.balanceOf(dsaWallet0.address)
        const poolTokenName = await poolToken.name()
        console.log("\tBalance before: ", poolBalance.toString(), poolTokenName)

        // PodToken is 99
        let podToken = await ethers.getContractAt(abis.basic.erc20, daiPod)
        const podBalance = await podToken.balanceOf(dsaWallet0.address)
        const podTokenName = await podToken.name()
        console.log("\tBalance before: ", podBalance.toString(), podTokenName)

        // Increase time by 11 days so we get back all DAI without early withdrawal fee
        await ethers.provider.send("evm_increaseTime", [11*24*60*60]);

        // Run spell transaction
        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        // After spell
        // Expect DAI balance to be equal to 99, because of no early withdrawal fee
        daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("After spell: ");
        console.log("\tBalance after: ", daiBalance.toString(), tokens.dai.symbol);
        expect(daiBalance).to.be.eq(ethers.utils.parseEther("99"));

        // Expect Pool Token Balance to be greater than 0
        const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", poolBalanceAfter.toString(), poolTokenName)
        expect(poolBalanceAfter).to.be.gt(ethers.utils.parseEther("0"));

        // Expect Pod Token Balance to equal 0
        const podBalanceAfter = await podToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", podBalanceAfter.toString(), podTokenName)
        expect(podBalanceAfter).to.be.eq(ethers.utils.parseEther("0"));
    });

    it("Should deposit and withdraw from pod, get back same amount of 99 DAI", async function() {
        const amount = ethers.utils.parseEther("99")
        const maxFee = 0;

        const spells = [
            {
                connector: ptConnectorName,
                method: "depositToPod",
                args: [prizePool, daiPod, dsaWallet0.address, amount, 0, 0]
            },
            {
                connector: ptConnectorName,
                method: "withdrawFromPod",
                args: [daiPod, amount, maxFee, 0, 0]
            }
        ]

        // Before spell
        // DAI balance is 0
        let daiToken = await ethers.getContractAt(abis.basic.erc20, token)
        let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("Before Spell:")
        console.log("\tBalance before: ", daiBalance.toString(), tokens.dai.symbol);

        // PoolToken is greater than 0
        let poolToken = await ethers.getContractAt(abis.basic.erc20, poolTokenAddress)
        const poolBalance = await poolToken.balanceOf(dsaWallet0.address)
        const poolTokenName = await poolToken.name()
        console.log("\tBalance before: ", poolBalance.toString(), poolTokenName)

        // PodToken is 0
        let podToken = await ethers.getContractAt(abis.basic.erc20, daiPod)
        const podBalance = await podToken.balanceOf(dsaWallet0.address)
        const podTokenName = await podToken.name()
        console.log("\tBalance before: ", podBalance.toString(), podTokenName)

        // Run spell transaction
        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        // After spell
        // Expect DAI balance to be equal to 99, because funds still in 'float'
        daiBalance = await daiToken.balanceOf(dsaWallet0.address);
        console.log("After spell: ");
        console.log("\tBalance after: ", daiBalance.toString(), tokens.dai.symbol);
        expect(daiBalance).to.be.eq(ethers.utils.parseEther("99"));

        // Expect Pool Token Balance to greater than 0
        const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", poolBalanceAfter.toString(), poolTokenName)
        expect(poolBalanceAfter).to.be.gt(ethers.utils.parseEther("0"));

        // Expect Pod Token Balance to equal 0
        const podBalanceAfter = await podToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", podBalanceAfter.toString(), podTokenName)
        expect(podBalanceAfter).to.be.eq(ethers.utils.parseEther("0"));
    });
  })

  describe("Main - UNISWAP POOL/ETH Prize Pool Test", function () {
    it("Should use uniswap to swap ETH for POOL, deposit to POOL/ETH LP, deposit POOL/ETH LP to PrizePool", async function () {
        const amount = ethers.utils.parseEther("100") // 100 POOL
        const slippage = ethers.utils.parseEther("0.03");
        const setId = "83478237"

        const UniswapV2Router02ABI = [
            "function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts)"
        ];

        const UniswapV2Router02 = await ethers.getContractAt(UniswapV2Router02ABI, "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D");
        const amounts = await UniswapV2Router02.getAmountsOut(amount, [poolTokenAddress, WETHAddress]);
        const unitAmount = ethers.utils.parseEther(((amounts[1]*1.03)/amounts[0]).toString());

        const spells = [
            {
                connector: uniswapConnectorName,
                method: "buy",
                args: [poolTokenAddress, tokens.eth.address, amount, unitAmount, 0, setId]
            },
            {
                connector: uniswapConnectorName,
                method: "deposit",
                args: [poolTokenAddress, tokens.eth.address, amount, unitAmount, slippage, 0, setId]
            },
            {
                connector: ptConnectorName,
                method: "depositTo",
                args: [uniswapPoolETHLPPrizePool, dsaWallet0.address, 0, ptUniswapPOOLETHLPTicket, constants.address_zero, setId, 0]
            }
        ]

        // Before Spell
        // ETH balance
        let ethBalance = await ethers.provider.getBalance(dsaWallet0.address);
        console.log("Before spell:");
        console.log("\tBalance before: ", ethBalance.toString(), "ETH");

        // PoolToken > 0
        let poolToken = await ethers.getContractAt(abis.basic.erc20, poolTokenAddress)
        const poolBalance = await poolToken.balanceOf(dsaWallet0.address)
        const poolTokenName = await poolToken.name()
        console.log("\tBalance before: ", poolBalance.toString(), poolTokenName)

        // Uniswap POOL/ETH LP is 0
        let uniswapLPToken = await ethers.getContractAt(abis.basic.erc20, uniswapPOOLETHLPToken)
        const uniswapPoolEthBalance = await uniswapLPToken.balanceOf(dsaWallet0.address)
        const uniswapPoolEthLPTokenName = await uniswapLPToken.name()
        console.log("\tBalance before: ", uniswapPoolEthBalance.toString(), uniswapPoolEthLPTokenName)

        // Expect PT Uniswap POOL/ETH LP is 0
        let ptUniswapPoolEthToken = await ethers.getContractAt(abis.basic.erc20, ptUniswapPOOLETHLPTicket)
        const ptUniswapPoolEthBalance = await ptUniswapPoolEthToken.balanceOf(dsaWallet0.address)
        const ptUniswapPoolEthLPTokenName = await ptUniswapPoolEthToken.name()
        console.log("\tBalance before: ", ptUniswapPoolEthBalance.toString(), ptUniswapPoolEthLPTokenName)

        // Run spell transaction
        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        // After spell
        // ETH balance < 0
        ethBalance = await ethers.provider.getBalance(dsaWallet0.address);
        console.log("After spell:");
        console.log("\tBalance after: ", ethBalance.toString(), "ETH");

        // Expect Pool Token Balance to greater than 0
        const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", poolBalanceAfter.toString(), poolTokenName)
        expect(poolBalanceAfter).to.be.eq(poolBalance);

        // Expect Uniswap POOL/ETH LP to greater than 0
        const uniswapPoolEthBalanceAfter = await uniswapLPToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", uniswapPoolEthBalanceAfter.toString(), uniswapPoolEthLPTokenName)
        expect(uniswapPoolEthBalanceAfter).to.be.eq(ethers.utils.parseEther("0"));

        // Expect PT Uniswap POOL/ETH LP to greater than 0
        const ptUniswapPoolEthBalanceAfter = await ptUniswapPoolEthToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", ptUniswapPoolEthBalanceAfter.toString(), ptUniswapPoolEthLPTokenName)
        expect(ptUniswapPoolEthBalanceAfter).to.be.gt(ethers.utils.parseEther("0"));

        expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(ethers.utils.parseEther("9"));
    });

    it("Should wait 11 days, withdraw all PrizePool, get back Uniswap LP, claim POOL, deposit claimed POOL into Pool PrizePool", async function () {
        let ptUniswapPoolEthToken = await ethers.getContractAt(abis.basic.erc20, ptUniswapPOOLETHLPTicket)
        const ptUniswapPoolEthBalance = await ptUniswapPoolEthToken.balanceOf(dsaWallet0.address)
        const setId = "83478237"

        const spells = [
            {
                connector: ptConnectorName,
                method: "withdrawInstantlyFrom",
                args: [uniswapPoolETHLPPrizePool, dsaWallet0.address, ptUniswapPoolEthBalance, ptUniswapPOOLETHLPTicket, 0, 0, 0]
            },
            {
                connector: ptConnectorName,
                method: "claim",
                args: [uniswapPoolETHLPFaucet , dsaWallet0.address, setId]
            },
            {
                connector: ptConnectorName,
                method: "depositTo",
                args: [poolPoolPrizePool, dsaWallet0.address, 0, ptPoolTicket, constants.address_zero, setId, 0]
            }
        ]

        // Before spell
        console.log("Before spell:");
        // PoolToken
        let poolToken = await ethers.getContractAt(abis.basic.erc20, poolTokenAddress)
        const poolBalance = await poolToken.balanceOf(dsaWallet0.address)
        const poolTokenName = await poolToken.name()
        console.log("\tBalance before: ", poolBalance.toString(), poolTokenName)

        // Uniswap POOL/ETH LP is 0
        let uniswapLPToken = await ethers.getContractAt(abis.basic.erc20, uniswapPOOLETHLPToken)
        const uniswapPoolEthBalance = await uniswapLPToken.balanceOf(dsaWallet0.address)
        const uniswapPoolEthLPTokenName = await uniswapLPToken.name()
        console.log("\tBalance before: ", uniswapPoolEthBalance.toString(), uniswapPoolEthLPTokenName)

        // Expect PT Uniswap POOL/ETH LP > 0
        const ptUniswapPoolEthLPTokenName = await ptUniswapPoolEthToken.name()
        console.log("\tBalance before: ", ptUniswapPoolEthBalance.toString(), ptUniswapPoolEthLPTokenName)

        // PoolTogether Pool Ticket
        let poolPoolTicket = await ethers.getContractAt(abis.basic.erc20, ptPoolTicket)
        const poolPoolTicketBalance = await poolPoolTicket.balanceOf(dsaWallet0.address)
        const poolPoolTicketName = await poolPoolTicket.name()
        console.log("\tBalance before: ", poolPoolTicketBalance.toString(), poolPoolTicketName)

        // Increase time by 11 days so we get back all DAI without early withdrawal fee
        await ethers.provider.send("evm_increaseTime", [11*24*60*60]);

        // Run spell transaction
        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
        const receipt = await tx.wait()

        // After spell
        console.log("After spell:");
        // Expect Pool Token Balance to be greater than balance before spell
        const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", poolBalanceAfter.toString(), poolTokenName)
        expect(poolBalanceAfter).to.be.eq(poolBalance);

        // Expect Uniswap POOL/ETH LP to greater than 0
        const uniswapPoolEthBalanceAfter = await uniswapLPToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", uniswapPoolEthBalanceAfter.toString(), uniswapPoolEthLPTokenName)
        expect(uniswapPoolEthBalanceAfter).to.be.gt(ethers.utils.parseEther("0"));

        // Expect PT Uniswap POOL/ETH LP equal 0
        const ptUniswapPoolEthBalanceAfter = await ptUniswapPoolEthToken.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", ptUniswapPoolEthBalanceAfter.toString(), ptUniswapPoolEthLPTokenName)
        expect(ptUniswapPoolEthBalanceAfter).to.be.eq(ethers.utils.parseEther("0"));

        // Expoect PoolTogether Pool Ticket > 0
        const poolPoolTicketBalanceAfter = await poolPoolTicket.balanceOf(dsaWallet0.address)
        console.log("\tBalance after: ", poolPoolTicketBalanceAfter.toString(), poolPoolTicketName)
        expect(poolPoolTicketBalanceAfter).to.be.gt(ethers.utils.parseEther("0"));
    });
  })
})