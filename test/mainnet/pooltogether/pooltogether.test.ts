import { expect } from "chai";
import hre from "hardhat";
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle;

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";

import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";
import { constants } from "../../../scripts/constant/constant";
import { tokens } from "../../../scripts/tests/mainnet/tokens";
import type { Signer, Contract } from "ethers";

import {
  ConnectV2Compound__factory,
  ConnectV2PoolTogether__factory,
  ConnectV2UniswapV2__factory,
} from "../../../typechain";

const DAI_TOKEN_ADDR = tokens.dai.address; // DAI Token

// PoolTogether Address: https://docs.pooltogether.com/resources/networks/ethereum
const DAI_PRIZE_POOL_ADDR = "0xEBfb47A7ad0FD6e57323C8A42B2E5A6a4F68fc1a"; // DAI Prize Pool
const PT_DAI_TICKET_ADDR = "0x334cBb5858417Aee161B53Ee0D5349cCF54514CF"; // PT DAI Ticket
const DAI_POOL_FAUCET_ADDR = "0xF362ce295F2A4eaE4348fFC8cDBCe8d729ccb8Eb"; // DAI POOL Faucet
const POOL_TOKEN_ADDRESS = "0x0cEC1A9154Ff802e7934Fc916Ed7Ca50bDE6844e"; // POOL Tocken
const TOKEN_FAUCET_PROXY_FACTORY_ADDR =
  "0xE4E9cDB3E139D7E8a41172C20b6Ed17b6750f117"; // TokenFaucetProxyFactory for claimAll
const DAI_POD_ADDR = "0x2f994e2E4F3395649eeE8A89092e63Ca526dA829"; // DAI Pod
const UNISWAP_POOLETHLP_PRIZE_POOL_ADDR =
  "0x3AF7072D29Adde20FC7e173a7CB9e45307d2FB0A"; // Uniswap Pool/ETH LP PrizePool
const UNISWAP_POOLETHLP_FAUCET_ADDR =
  "0x9A29401EF1856b669f55Ae5b24505b3B6fAEb370"; // Uniswap Pool/ETH LP Faucet
const UNISWAP_POOLETHLP_TOKEN_ADDR =
  "0x85cb0bab616fe88a89a35080516a8928f38b518b"; // Uniswap Pool/ETH Token
const PT_UNISWAP_POOLETHLP_TICKET_ADDR =
  "0xeb8928ee92efb06c44d072a24c2bcb993b61e543"; // Pool Together Uniswap Pool/ETH LP Ticket
const POOL_PRIZE_POOL_ADDR = "0x396b4489da692788e327e2e4b2b0459a5ef26791"; // POOL Prize Pool
const PT_POOL_TICKET_ADDR = "0x27d22a7648e955e510a40bdb058333e9190d12d4"; // Pool Together POOL Ticket
const WETH_ADDR = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"; // WETH
const DAI_POD_TOKEN_DROP = "0xc5209623E3dFdf9C0cCbe497c8012883C4147731";

// Community WETH Prize Pool (Rari): https://reference-app.pooltogether.com/pools/mainnet/0xa88ca010b32a54d446fc38091ddbca55750cbfc3/manage#stats
const WETH_PRIZE_POOL_ADDR = "0xa88ca010b32a54d446fc38091ddbca55750cbfc3"; // Community WETH Prize Pool (Rari)
const WETH_POOL_TICKET_ADDR = "0x9b5c30aeb9ce2a6a121cea9a85bc0d662f6d9b40"; // Community WETH Prize Pool Ticket (Rari)

const prizePoolABI = [
  "function calculateEarlyExitFee( address from, address controlledToken, uint256 amount) external returns ( uint256 exitFee, uint256 burnedCredit)",
];

const podABI = [
  "function getEarlyExitFee(uint256 amount) external returns (uint256)",
  "function balanceOfUnderlying(address user) external view returns (uint256 amount)",
  "function drop() public returns (uint256)",
  "function balanceOf(address account) external view returns (uint256)",
];

const POD_FACTORY_ADDRESS = "0x4e3a9f9fbafb2ec49727cffa2a411f7a0c1c4ce1";
const podFactoryABI = [
  "function create( address _prizePool, address _ticket, address _faucet, address _manager, uint8 _decimals) external returns (address pod)",
];

const tokenDropABI = [
  "function claim(address user) external returns (uint256)",
];

describe("PoolTogether", function() {
  const connectorName = "COMPOUND-TEST-A";
  const uniswapConnectorName = "UNISWAP-TEST-A";
  const ptConnectorName = "POOLTOGETHER-TEST-A";

  let dsaWallet0: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;
  let ptConnector: any;
  let uniswapConnector: any;

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;
  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 12696000,
          },
        },
      ],
    });
    
    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(
      abis.core.connectorsV2,
      addresses.core.connectorsV2
    );

    // Deploy and enable Compound Connector
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2Compound__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });

    // Deploy and enable Pool Together Connector
    ptConnector = await deployAndEnableConnector({
      connectorName: ptConnectorName,
      contractArtifact: ConnectV2PoolTogether__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });

    // Deploy and enable Uniswap Connector
    uniswapConnector = await deployAndEnableConnector({
      connectorName: uniswapConnectorName,
      contractArtifact: ConnectV2UniswapV2__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
  });

  it("Should have contracts deployed.", async function() {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!ptConnector.address).to.be.true;
    expect(!!uniswapConnector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function() {
    it("Should build DSA v2", async function() {
      dsaWallet0 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit 10 ETH into DSA wallet", async function() {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10"),
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseEther("10")
      );
    });
  });

  describe("Main - DAI Prize Pool Test", function() {
    it("Should deposit 1 ETH in Compound", async function() {
      const amount = ethers.utils.parseEther("1"); // 1 ETH
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: ["ETH-A", amount, 0, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("9")
      );
    });

    it("Should borrow 100 DAI from Compound and deposit DAI into DAI Prize Pool", async function() {
      const amount = ethers.utils.parseEther("100"); // 100 DAI
      const setId = "83478237";
      const spells = [
        {
          connector: connectorName,
          method: "borrow",
          args: ["DAI-A", amount, 0, setId],
        },
        {
          connector: ptConnectorName,
          method: "depositTo",
          args: [DAI_PRIZE_POOL_ADDR, amount, PT_DAI_TICKET_ADDR, setId, 0],
        },
      ];
      // Before Spell
      let daiToken = await ethers.getContractAt(
        abis.basic.erc20,
        DAI_TOKEN_ADDR
      );
      let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(daiBalance, `DAI balance is 0`).to.be.eq(
        ethers.utils.parseEther("0")
      );

      let cToken = await ethers.getContractAt(
        abis.basic.erc20,
        PT_DAI_TICKET_ADDR
      );
      const balance = await cToken.balanceOf(dsaWallet0.address);
      expect(balance, `PoolTogether DAI Ticket balance is 0`).to.be.eq(0);

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After spell
      daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(
        daiBalance,
        `Expect DAI balance to still equal 0 since it was deposited into Prize Pool`
      ).to.be.eq(0);

      const balanceAfter = await cToken.balanceOf(dsaWallet0.address);
      expect(
        balanceAfter,
        `PoolTogether DAI Ticket balance equals 100`
      ).to.be.eq(ethers.utils.parseEther("100"));

      // ETH used for transaction
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("9")
      );
    });

    it("Should wait 11 days, withdraw all PrizePool, get back 100 DAI, and claim POOL", async function() {
      const amount = ethers.utils.parseEther("100"); // 100 DAI

      let prizePoolContract = new ethers.Contract(
        DAI_PRIZE_POOL_ADDR,
        prizePoolABI,
        ethers.provider
      );
      let earlyExitFee = await prizePoolContract.callStatic[
        "calculateEarlyExitFee"
      ](dsaWallet0.address, PT_DAI_TICKET_ADDR, amount);
      expect(
        earlyExitFee.exitFee,
        "Exit Fee equal to 1 DAI because starts at 10%"
      ).to.be.eq(ethers.utils.parseEther("1"));

      const spells = [
        {
          connector: ptConnectorName,
          method: "withdrawInstantlyFrom",
          args: [
            DAI_PRIZE_POOL_ADDR,
            amount,
            PT_DAI_TICKET_ADDR,
            earlyExitFee.exitFee,
            0,
            0,
          ],
        },
        {
          connector: ptConnectorName,
          method: "claim",
          args: [DAI_POOL_FAUCET_ADDR, 0],
        },
      ];

      // Before spell
      let daiToken = await ethers.getContractAt(
        abis.basic.erc20,
        DAI_TOKEN_ADDR
      );
      let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(daiBalance, `DAI balance equals 0`).to.be.eq(
        ethers.utils.parseEther("0")
      );

      let cToken = await ethers.getContractAt(
        abis.basic.erc20,
        PT_DAI_TICKET_ADDR
      );
      const balance = await cToken.balanceOf(dsaWallet0.address);
      expect(balance, `PoolTogether Dai Ticket is 100`).to.be.eq(
        ethers.utils.parseEther("100")
      );

      let poolToken = await ethers.getContractAt(
        abis.basic.erc20,
        POOL_TOKEN_ADDRESS
      );
      const poolBalance = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalance, `POOL Token equals 0`).to.be.eq(
        ethers.utils.parseEther("0")
      );

      // Increase time by 11 days so we get back all DAI without early withdrawal fee
      await ethers.provider.send("evm_increaseTime", [11 * 24 * 60 * 60]);

      earlyExitFee = await prizePoolContract.callStatic[
        "calculateEarlyExitFee"
      ](dsaWallet0.address, PT_DAI_TICKET_ADDR, amount);
      expect(
        earlyExitFee.exitFee,
        "Exit Fee equal to 0 DAI because past 10 days"
      ).to.be.eq(0);

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After spell
      daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(
        daiBalance,
        `DAI balance to be equal to 100, because of no early withdrawal fee`
      ).to.be.eq(ethers.utils.parseEther("100"));

      const balanceAfter = await cToken.balanceOf(dsaWallet0.address);
      expect(balanceAfter, `PoolTogether Dai Ticket to equal 0`).to.be.eq(0);

      const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address);
      expect(
        poolBalanceAfter,
        `POOL Token Balance to be greater than 0`
      ).to.be.gt(ethers.utils.parseEther("0"));
    });

    it("Should deposit and withdraw all PrizePool, get back less than 100 DAI", async function() {
      const amount = ethers.utils.parseEther("100"); // 100 DAI
      const exitFee = ethers.utils.parseEther("1"); // 1 DAI is 10% of 100 DAI
      const spells = [
        {
          connector: ptConnectorName,
          method: "depositTo",
          args: [DAI_PRIZE_POOL_ADDR, amount, PT_DAI_TICKET_ADDR, 0, 0],
        },
        {
          connector: ptConnectorName,
          method: "withdrawInstantlyFrom",
          args: [
            DAI_PRIZE_POOL_ADDR,
            amount,
            PT_DAI_TICKET_ADDR,
            exitFee,
            0,
            0,
          ],
        },
      ];

      // Before spell
      let daiToken = await ethers.getContractAt(
        abis.basic.erc20,
        DAI_TOKEN_ADDR
      );
      let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(daiBalance, `DAI Balance equals 0`).to.be.eq(
        ethers.utils.parseEther("100")
      );

      let cToken = await ethers.getContractAt(
        abis.basic.erc20,
        PT_DAI_TICKET_ADDR
      );
      const balance = await cToken.balanceOf(dsaWallet0.address);
      expect(balance, `PoolTogether DAI Ticket equals 0`).to.be.eq(0);

      let poolToken = await ethers.getContractAt(
        abis.basic.erc20,
        POOL_TOKEN_ADDRESS
      );
      const poolBalance = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalance, `PoolTogether Token greater than 0`).to.be.gt(0);

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After spell
      daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(
        daiBalance,
        `DAI balance to be less than 100, because of early withdrawal fee`
      ).to.be.lt(ethers.utils.parseEther("100"));

      const balanceAfter = await cToken.balanceOf(dsaWallet0.address);
      expect(balanceAfter, `PoolTogether Dai Ticket to equal 0`).to.be.eq(0);

      const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalanceAfter, `POOL Token Balance to greater than 0`).to.be.gt(
        ethers.utils.parseEther("0")
      );
    });

    it("Should deposit, wait 11 days, and withdraw all PrizePool, get 99 DAI, and claim all POOL using claimAll", async function() {
      const amount = ethers.utils.parseEther("99"); // 99 DAI
      const depositSpells = [
        {
          connector: ptConnectorName,
          method: "depositTo",
          args: [DAI_PRIZE_POOL_ADDR, amount, PT_DAI_TICKET_ADDR, 0, 0],
        },
      ];

      // Before spell
      let daiToken = await ethers.getContractAt(
        abis.basic.erc20,
        DAI_TOKEN_ADDR
      );
      let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(daiBalance, `DAI balance less than 100`).to.be.lt(
        ethers.utils.parseEther("100")
      );

      let cToken = await ethers.getContractAt(
        abis.basic.erc20,
        PT_DAI_TICKET_ADDR
      );
      const balance = await cToken.balanceOf(dsaWallet0.address);
      expect(balance, `PoolTogether DAI Ticket equal 0`).to.be.eq(0);

      let poolToken = await ethers.getContractAt(
        abis.basic.erc20,
        POOL_TOKEN_ADDRESS
      );
      const poolBalance = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalance, `POOL Token is greater than 0`).to.be.gt(
        ethers.utils.parseEther("0")
      );

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(depositSpells), wallet1.address);
      const receipt = await tx.wait();

      const prizePoolContract = new ethers.Contract(
        DAI_PRIZE_POOL_ADDR,
        prizePoolABI,
        ethers.provider
      );
      let earlyExitFee = await prizePoolContract.callStatic[
        "calculateEarlyExitFee"
      ](dsaWallet0.address, PT_DAI_TICKET_ADDR, amount);
      expect(
        earlyExitFee.exitFee,
        "Exit Fee equal to .99 DAI because starts at 10%"
      ).to.be.eq(ethers.utils.parseEther(".99"));

      // Increase time by 11 days so we get back all DAI without early withdrawal fee
      await ethers.provider.send("evm_increaseTime", [11 * 24 * 60 * 60]);

      earlyExitFee = await prizePoolContract.callStatic[
        "calculateEarlyExitFee"
      ](dsaWallet0.address, PT_DAI_TICKET_ADDR, amount);
      expect(
        earlyExitFee.exitFee,
        "Exit Fee equal to 0 DAI because past 10 days"
      ).to.be.eq(0);

      const withdrawSpells = [
        {
          connector: ptConnectorName,
          method: "withdrawInstantlyFrom",
          args: [
            DAI_PRIZE_POOL_ADDR,
            amount,
            PT_DAI_TICKET_ADDR,
            earlyExitFee.exitFee,
            0,
            0,
          ],
        },
        {
          connector: ptConnectorName,
          method: "claimAll",
          args: [TOKEN_FAUCET_PROXY_FACTORY_ADDR, [DAI_POOL_FAUCET_ADDR]],
        },
      ];

      // Run spell transaction
      const tx2 = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(withdrawSpells), wallet1.address);
      const receipt2 = await tx2.wait();

      // After spell
      daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(daiBalance, `DAI balance equals 99`).to.be.eq(
        ethers.utils.parseEther("99")
      );

      const balanceAfter = await cToken.balanceOf(dsaWallet0.address);
      expect(balanceAfter, `PoolTogether DAI Ticket equal 0`).to.be.eq(0);

      // Expect
      const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalanceAfter, `Pool Token to be greateir than 0`).to.be.gt(
        ethers.utils.parseEther("0")
      );
    });
  });

  describe("Main - DAI Pod Test", function() {
    it("Should deposit 99 DAI in DAI Pod", async function() {
      const amount = ethers.utils.parseEther("99"); // 99 DAI
      const spells = [
        {
          connector: ptConnectorName,
          method: "depositToPod",
          args: [DAI_TOKEN_ADDR, DAI_POD_ADDR, amount, 0, 0],
        },
      ];

      // Before spell
      let daiToken = await ethers.getContractAt(
        abis.basic.erc20,
        DAI_TOKEN_ADDR
      );
      let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(daiBalance, `DAI balance equals 99`).to.be.eq(
        ethers.utils.parseEther("99")
      );

      let poolToken = await ethers.getContractAt(
        abis.basic.erc20,
        POOL_TOKEN_ADDRESS
      );
      const poolBalance = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalance, `POOL Token greater than 0`).to.be.gte(0);

      let podToken = await ethers.getContractAt(abis.basic.erc20, DAI_POD_ADDR);
      const podBalance = await podToken.balanceOf(dsaWallet0.address);
      expect(podBalance, `Pod DAI Token equals 0`).to.be.eq(0);

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After spell
      daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(daiBalance, `DAI equals 0`).to.be.eq(0);

      const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalanceAfter, `POOL Token greater than 0`).to.be.gt(0);

      const podBalanceAfter = await podToken.balanceOf(dsaWallet0.address);
      expect(podBalanceAfter, `Pod DAI token greater than 0`).to.be.eq(
        ethers.utils.parseEther("99")
      );
    });

    it("Should claim rewards from pod token drop", async function() {
      const spells = [
        {
          connector: ptConnectorName,
          method: "claimPodTokenDrop",
          args: [DAI_POD_TOKEN_DROP, 0],
        },
      ];

      const tokenDropContract = new ethers.Contract(
        DAI_POD_TOKEN_DROP,
        tokenDropABI,
        ethers.provider
      );
      const podContract = new ethers.Contract(
        DAI_POD_ADDR,
        podABI,
        masterSigner
      );

      // drop(): Claim TokenDrop asset for PrizePool Pod and transfers token(s) to external Pod TokenDrop
      // dropt() also calls batch which, Deposit Pod float into PrizePool. Deposits the current float
      // amount into the PrizePool and claims current POOL rewards.
      const dropTx = await podContract.drop();
      await dropTx.wait();

      // POOL Rewards able to claim from Pod Token Drop
      let claimAmount = await tokenDropContract.callStatic["claim"](
        dsaWallet0.address
      );

      // Before spell
      let poolToken = await ethers.getContractAt(
        abis.basic.erc20,
        POOL_TOKEN_ADDRESS
      );
      const poolBalance = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalance, `POOL Token greater than 0`).to.be.gt(0);

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After spell
      const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address);
      const total = claimAmount.add(poolBalance);
      expect(poolBalanceAfter, `POOL Token same as before spell`).to.be.eq(
        total
      );
    });

    it("Should wait 11 days, withdraw all podTokens, get back 99 DAI", async function() {
      const amount = ethers.utils.parseEther("99"); // 99 DAI

      const podContract = new ethers.Contract(
        DAI_POD_ADDR,
        podABI,
        ethers.provider
      );
      let maxFee = await podContract.callStatic["getEarlyExitFee"](amount);
      // maxFee depends on if token has been deposited to PrizePool yet
      // since we called drop in previous test case, the tokens were deposited to PrizePool
      expect(
        maxFee,
        "Exit Fee equal to .99 DAI because token still in float"
      ).to.be.eq(ethers.utils.parseEther(".99"));

      const spells = [
        {
          connector: ptConnectorName,
          method: "withdrawFromPod",
          args: [DAI_POD_ADDR, amount, maxFee, 0, 0],
        },
      ];

      // Before spell
      let daiToken = await ethers.getContractAt(
        abis.basic.erc20,
        DAI_TOKEN_ADDR
      );
      let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(daiBalance, `DAI Balance equals 0`).to.be.eq(0);

      let poolToken = await ethers.getContractAt(
        abis.basic.erc20,
        POOL_TOKEN_ADDRESS
      );
      const poolBalance = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalance, `POOL Token balance greater than 0`).to.be.gt(0);

      let podToken = await ethers.getContractAt(abis.basic.erc20, DAI_POD_ADDR);
      const podBalance = await podToken.balanceOf(dsaWallet0.address);
      expect(podBalance, `Pod DAI Token equals 99`).to.be.eq(
        ethers.utils.parseEther("99")
      );

      // Increase time by 11 days so we get back all DAI without early withdrawal fee
      await ethers.provider.send("evm_increaseTime", [11 * 24 * 60 * 60]);

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After spell
      daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(
        daiBalance,
        `DAI balance equals 99, because of no early withdrawal fee`
      ).to.be.eq(ethers.utils.parseEther("99"));

      const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalanceAfter, `POOL Token to be greater than 0`).to.be.gt(0);

      const podBalanceAfter = await podToken.balanceOf(dsaWallet0.address);
      expect(podBalanceAfter, `Pod DAI Token equals 0`).to.be.eq(0);
    });

    it("Should deposit and withdraw from pod, get back same amount of 99 DAI", async function() {
      const amount = ethers.utils.parseEther("99");
      const maxFee = 0; // maxFee 0 since it doesn't give chance for Pod to actually deposit into PrizePool

      const spells = [
        {
          connector: ptConnectorName,
          method: "depositToPod",
          args: [DAI_TOKEN_ADDR, DAI_POD_ADDR, amount, 0, 0],
        },
        {
          connector: ptConnectorName,
          method: "withdrawFromPod",
          args: [DAI_POD_ADDR, amount, maxFee, 0, 0],
        },
      ];

      // Before spell
      let daiToken = await ethers.getContractAt(
        abis.basic.erc20,
        DAI_TOKEN_ADDR
      );
      let daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(daiBalance, `DAI equals 99`).to.be.eq(
        ethers.utils.parseEther("99")
      );

      let poolToken = await ethers.getContractAt(
        abis.basic.erc20,
        POOL_TOKEN_ADDRESS
      );
      const poolBalance = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalance, `POOL Token greater than 0`).to.be.gt(0);

      // PodToken is 0
      let podToken = await ethers.getContractAt(abis.basic.erc20, DAI_POD_ADDR);
      const podBalance = await podToken.balanceOf(dsaWallet0.address);
      expect(podBalance, `Pod DAI Token equals 0`).to.be.eq(0);

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After spell
      daiBalance = await daiToken.balanceOf(dsaWallet0.address);
      expect(
        daiBalance,
        `DAI balance to be equal to 99, because funds still in 'float`
      ).to.be.eq(ethers.utils.parseEther("99"));

      const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalanceAfter, `POOL Token same as before spell`).to.be.eq(
        poolBalance
      );

      // Expect Pod Token Balance to equal 0
      const podBalanceAfter = await podToken.balanceOf(dsaWallet0.address);
      expect(podBalanceAfter, `Pod DAI Token equals 0`).to.be.eq(
        ethers.utils.parseEther("0")
      );
    });
  });

  describe("Main - UNISWAP POOL/ETH Prize Pool Test", function() {
    it("Should use uniswap to swap ETH for POOL, deposit to POOL/ETH LP, deposit POOL/ETH LP to PrizePool", async function() {
      const amount = ethers.utils.parseEther("100"); // 100 POOL
      const slippage = ethers.utils.parseEther("0.03");
      const setId = "83478237";

      const UniswapV2Router02ABI = [
        "function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts)",
      ];

      // Get amount of ETH for 100 POOL from Uniswap
      const UniswapV2Router02 = await ethers.getContractAt(
        UniswapV2Router02ABI,
        "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
      );
      const amounts = await UniswapV2Router02.getAmountsOut(amount, [
        POOL_TOKEN_ADDRESS,
        WETH_ADDR,
      ]);
      const unitAmount = ethers.utils.parseEther(
        ((amounts[1] * 1.03) / amounts[0]).toString()
      );

      const spells = [
        {
          connector: uniswapConnectorName,
          method: "buy",
          args: [
            POOL_TOKEN_ADDRESS,
            tokens.eth.address,
            amount,
            unitAmount,
            0,
            setId,
          ],
        },
        {
          connector: uniswapConnectorName,
          method: "deposit",
          args: [
            POOL_TOKEN_ADDRESS,
            tokens.eth.address,
            amount,
            unitAmount,
            slippage,
            0,
            setId,
          ],
        },
        {
          connector: ptConnectorName,
          method: "depositTo",
          args: [
            UNISWAP_POOLETHLP_PRIZE_POOL_ADDR,
            0,
            PT_UNISWAP_POOLETHLP_TICKET_ADDR,
            setId,
            0,
          ],
        },
      ];

      // Before Spell
      let ethBalance = await ethers.provider.getBalance(dsaWallet0.address);
      expect(ethBalance, `ETH Balance equals 9`).to.be.eq(
        ethers.utils.parseEther("9")
      );

      let poolToken = await ethers.getContractAt(
        abis.basic.erc20,
        POOL_TOKEN_ADDRESS
      );
      const poolBalance = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalance, `POOL Token greater than 0`).to.be.gte(0);

      let uniswapLPToken = await ethers.getContractAt(
        abis.basic.erc20,
        UNISWAP_POOLETHLP_TOKEN_ADDR
      );
      const uniswapPoolEthBalance = await uniswapLPToken.balanceOf(
        dsaWallet0.address
      );
      expect(uniswapPoolEthBalance, `Uniswap POOL/ETH LP equals 0`).to.be.eq(0);

      let ptUniswapPoolEthToken = await ethers.getContractAt(
        abis.basic.erc20,
        PT_UNISWAP_POOLETHLP_TICKET_ADDR
      );
      const ptUniswapPoolEthBalance = await ptUniswapPoolEthToken.balanceOf(
        dsaWallet0.address
      );
      expect(
        ptUniswapPoolEthBalance,
        `PoolTogether Uniswap POOL?ETH LP equals 0`
      ).to.be.eq(0);

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After spell
      ethBalance = await ethers.provider.getBalance(dsaWallet0.address);
      expect(ethBalance, `ETH Balance less than 9`).to.be.lt(
        ethers.utils.parseEther("9")
      );

      const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalanceAfter, `POOL Token to be same after spell`).to.be.eq(
        poolBalance
      );

      const uniswapPoolEthBalanceAfter = await uniswapLPToken.balanceOf(
        dsaWallet0.address
      );
      expect(
        uniswapPoolEthBalanceAfter,
        `Uniswap POOL/ETH LP equals 0`
      ).to.be.eq(0);

      const ptUniswapPoolEthBalanceAfter = await ptUniswapPoolEthToken.balanceOf(
        dsaWallet0.address
      );
      expect(
        ptUniswapPoolEthBalanceAfter,
        `PT Uniswap POOL/ETH LP to greater than 0`
      ).to.be.gt(0);
    });

    it("Should withdraw all PrizePool, get back Uniswap LP, claim POOL, deposit claimed POOL into Pool PrizePool", async function() {
      let ptUniswapPoolEthToken = await ethers.getContractAt(
        abis.basic.erc20,
        PT_UNISWAP_POOLETHLP_TICKET_ADDR
      );
      const ptUniswapPoolEthBalance = await ptUniswapPoolEthToken.balanceOf(
        dsaWallet0.address
      );
      const setId = "83478237";

      let uniswapPrizePoolContract = new ethers.Contract(
        UNISWAP_POOLETHLP_PRIZE_POOL_ADDR,
        prizePoolABI,
        ethers.provider
      );
      let earlyExitFee = await uniswapPrizePoolContract.callStatic[
        "calculateEarlyExitFee"
      ](
        dsaWallet0.address,
        PT_UNISWAP_POOLETHLP_TICKET_ADDR,
        ptUniswapPoolEthBalance
      );
      expect(
        earlyExitFee.exitFee,
        "Exit Fee equals 0 because no early exit fee for this prize pool"
      ).to.be.eq(0);

      const spells = [
        {
          connector: ptConnectorName,
          method: "withdrawInstantlyFrom",
          args: [
            UNISWAP_POOLETHLP_PRIZE_POOL_ADDR,
            ptUniswapPoolEthBalance,
            PT_UNISWAP_POOLETHLP_TICKET_ADDR,
            earlyExitFee.exitFee,
            0,
            0,
          ],
        },
        {
          connector: ptConnectorName,
          method: "claim",
          args: [UNISWAP_POOLETHLP_FAUCET_ADDR, setId],
        },
        {
          connector: ptConnectorName,
          method: "depositTo",
          args: [POOL_PRIZE_POOL_ADDR, 0, PT_POOL_TICKET_ADDR, setId, 0],
        },
      ];

      // Before spell
      let poolToken = await ethers.getContractAt(
        abis.basic.erc20,
        POOL_TOKEN_ADDRESS
      );
      const poolBalance = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalance, `POOL Token greater than 0`).to.be.gt(0);

      // Uniswap POOL/ETH LP is 0
      let uniswapLPToken = await ethers.getContractAt(
        abis.basic.erc20,
        UNISWAP_POOLETHLP_TOKEN_ADDR
      );
      const uniswapPoolEthBalance = await uniswapLPToken.balanceOf(
        dsaWallet0.address
      );
      expect(uniswapPoolEthBalance, `Uniswap POOL/ETH LP equals 0`).to.be.eq(0);

      expect(
        ptUniswapPoolEthBalance,
        `PT Uniswap POOL/ETH LP greater than 0`
      ).to.be.gt(0);

      let poolPoolTicket = await ethers.getContractAt(
        abis.basic.erc20,
        PT_POOL_TICKET_ADDR
      );
      const poolPoolTicketBalance = await poolPoolTicket.balanceOf(
        dsaWallet0.address
      );
      expect(
        poolPoolTicketBalance,
        `PoolTogether POOL Ticket equals 0`
      ).to.be.eq(0);

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After spell
      const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address);
      expect(
        poolBalanceAfter,
        `Pool Token Balance equal to balance before spell`
      ).to.be.eq(poolBalance);

      const uniswapPoolEthBalanceAfter = await uniswapLPToken.balanceOf(
        dsaWallet0.address
      );
      expect(
        uniswapPoolEthBalanceAfter,
        `Uniswap POOL/ETH LP to greater than 0`
      ).to.be.gt(0);

      const ptUniswapPoolEthBalanceAfter = await ptUniswapPoolEthToken.balanceOf(
        dsaWallet0.address
      );
      expect(
        ptUniswapPoolEthBalanceAfter,
        `PT Uniswap POOL/ETH LP equal 0`
      ).to.be.eq(0);

      const poolPoolTicketBalanceAfter = await poolPoolTicket.balanceOf(
        dsaWallet0.address
      );
      expect(
        poolPoolTicketBalanceAfter,
        `PoolTogether POOL Ticket greater than 0`
      ).to.be.gt(0);
    });
  });

  describe("Main - WETH Prize Pool Test", function() {
    it("Deposit 1 ETH into WETH Prize Pool and withdraw immediately", async function() {
      const amount = ethers.utils.parseEther("1"); // 1 ETH
      const setId = "83478237";
      const spells = [
        {
          connector: ptConnectorName,
          method: "depositTo",
          args: [WETH_PRIZE_POOL_ADDR, amount, WETH_POOL_TICKET_ADDR, 0, setId],
        },
        {
          connector: ptConnectorName,
          method: "withdrawInstantlyFrom",
          args: [
            WETH_PRIZE_POOL_ADDR,
            amount,
            WETH_POOL_TICKET_ADDR,
            amount,
            setId,
            0,
          ],
        },
      ];
      // Before Spell
      const ethBalanceBefore = await ethers.provider.getBalance(
        dsaWallet0.address
      );

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After spell
      const ethBalanceAfter = await ethers.provider.getBalance(
        dsaWallet0.address
      );

      // ETH used for transaction
      expect(
        ethBalanceAfter,
        `ETH Balance less than before spell because of early withdrawal fee`
      ).to.be.lte(ethBalanceBefore);
    });

    it("Deposit 1 ETH into WETH Prize Pool, wait 14 days, then withdraw", async function() {
      const amount = ethers.utils.parseEther("1"); // 1 ETH
      const depositSpell = [
        {
          connector: ptConnectorName,
          method: "depositTo",
          args: [WETH_PRIZE_POOL_ADDR, amount, WETH_POOL_TICKET_ADDR, 0, 0],
        },
      ];

      const withdrawSpell = [
        {
          connector: ptConnectorName,
          method: "withdrawInstantlyFrom",
          args: [
            WETH_PRIZE_POOL_ADDR,
            amount,
            WETH_POOL_TICKET_ADDR,
            amount,
            0,
            0,
          ],
        },
      ];

      // Before Deposit Spell
      let ethBalanceBefore = await ethers.provider.getBalance(
        dsaWallet0.address
      );

      // Run deposit spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(depositSpell), wallet1.address);
      const receipt = await tx.wait();

      // After Deposit spell
      let ethBalanceAfter = await ethers.provider.getBalance(
        dsaWallet0.address
      );

      expect(ethBalanceAfter, `ETH Balance less than before spell`).to.be.lte(
        ethBalanceBefore
      );

      // Increase time by 11 days so we get back all ETH without early withdrawal fee
      await ethers.provider.send("evm_increaseTime", [14 * 24 * 60 * 60]);

      // Run withdraw spell transaction
      const tx2 = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(withdrawSpell), wallet1.address);
      const receipt2 = await tx.wait();

      // After Deposit spell
      ethBalanceAfter = await ethers.provider.getBalance(dsaWallet0.address);

      expect(
        ethBalanceAfter,
        `ETH Balance equal to before spell because no early exit fee`
      ).to.be.eq(ethBalanceBefore);
    });
  });

  describe("Main - WETH Pod Test", function() {
    let podAddress: string;
    it("Should deposit 1 ETH in WETH Pod and get Pod Ticket", async function() {
      const amount = ethers.utils.parseEther("1");

      // Create Pod for WETH Prize Pool (Rari)
      const podFactoryContract = new ethers.Contract(
        POD_FACTORY_ADDRESS,
        podFactoryABI,
        masterSigner
      );
      podAddress = await podFactoryContract.callStatic.create(
        WETH_PRIZE_POOL_ADDR,
        WETH_POOL_TICKET_ADDR,
        constants.address_zero,
        wallet0.address,
        18
      );
      await podFactoryContract.create(
        WETH_PRIZE_POOL_ADDR,
        WETH_POOL_TICKET_ADDR,
        constants.address_zero,
        wallet0.address,
        18
      );

      const spells = [
        {
          connector: ptConnectorName,
          method: "depositToPod",
          args: [WETH_ADDR, podAddress, amount, 0, 0],
        },
      ];

      // Before Deposit Spell
      const podContract = new ethers.Contract(
        podAddress,
        podABI,
        ethers.provider
      );
      let podBalanceBefore = await podContract.balanceOfUnderlying(
        dsaWallet0.address
      );
      expect(podBalanceBefore, `Pod balance equal to 0`).to.be.eq(0);

      let ethBalanceBefore = await ethers.provider.getBalance(
        dsaWallet0.address
      );

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After Deposit spell
      let ethBalanceAfter = await ethers.provider.getBalance(
        dsaWallet0.address
      );
      expect(ethBalanceAfter, `ETH balance less than before`).to.be.lt(
        ethBalanceBefore
      );

      let podBalanceAfter = await podContract.balanceOfUnderlying(
        dsaWallet0.address
      );
      expect(podBalanceAfter, `Pod balance equal to 1`).to.be.eq(
        ethers.utils.parseEther("1")
      );
    });

    it("Should withdraw 1 Ticket from WETH Pod and get back ETH", async function() {
      const amount = ethers.utils.parseEther("1");

      const podContract = new ethers.Contract(
        podAddress,
        podABI,
        ethers.provider
      );
      let maxFee = await podContract.callStatic["getEarlyExitFee"](amount);
      expect(
        maxFee,
        "Exit Fee equal to 0 DAI because token still in float"
      ).to.be.eq(0);
      // maxFee depends on if token has been deposited to PrizePool yet

      const spells = [
        {
          connector: ptConnectorName,
          method: "withdrawFromPod",
          args: [podAddress, amount, maxFee, 0, 0],
        },
      ];

      // Before Deposit Spell
      let podBalanceBefore = await podContract.balanceOfUnderlying(
        dsaWallet0.address
      );
      expect(podBalanceBefore, `Pod balance equal to 1`).to.be.eq(
        ethers.utils.parseEther("1")
      );

      let ethBalanceBefore = await ethers.provider.getBalance(
        dsaWallet0.address
      );

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After Deposit spell
      let ethBalanceAfter = await ethers.provider.getBalance(
        dsaWallet0.address
      );
      expect(ethBalanceAfter, `ETH balance greater than before`).to.be.gt(
        ethBalanceBefore
      );

      let podBalanceAfter = await podContract.balanceOfUnderlying(
        dsaWallet0.address
      );
      expect(podBalanceAfter, `Pod balance equal to 0`).to.be.eq(
        ethers.utils.parseEther("0")
      );
    });
  });
});
