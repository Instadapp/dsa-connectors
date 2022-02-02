import { expect } from "chai";
import hre from "hardhat";
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle;

const ALCHEMY_ID = process.env.ALCHEMY_ID;

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";

import { addresses } from "../../../scripts/tests/polygon/addresses";
import { abis } from "../../../scripts/constant/abis";
import { tokens } from "../../../scripts/tests/polygon/tokens";
import type { Signer, Contract } from "ethers";

import { ConnectV2AaveV2Polygon__factory, ConnectV2PoolTogetherPolygon__factory } from "../../../typechain";

const DAI_TOKEN_ADDR = tokens.dai.address; // DAI Token
// PoolTogether Address: https://docs.pooltogether.com/resources/networks/matic
const USDC_PRIZE_POOL_ADDR = "0xEE06AbE9e2Af61cabcb13170e01266Af2DEFa946"; // USDC Prize Pool
const PT_USDC_TICKET_ADDR = "0x473E484c722EF9ec6f63B509b07Bb9cfB258820b"; // PT USDC Ticket
const PT_USDC_SPONGSOR_TICKET_ADDR =
  "0x19c0e557ee5a9b456f613ba3d025a4dc45b52c35"; // PT USDC Sponsor Ticket
const USDC_POOL_FAUCET_ADDR = "0x6cbc003fE015D753180f072d904bA841b2415498"; // USDC POOL Faucet
const POOL_TOKEN_ADDRESS = "0x25788a1a171ec66Da6502f9975a15B609fF54CF6"; // POOL Tocken
const TOKEN_FAUCET_PROXY_FACTORY_ADDR =
  "0xeaa636304a7C8853324B6b603dCdE55F92dfbab1"; // TokenFaucetProxyFactory for claimAll

// Community WETH Prize Pool (Rari): https://reference-app.pooltogether.com/pools/mainnet/0xa88ca010b32a54d446fc38091ddbca55750cbfc3/manage#stats
const WETH_PRIZE_POOL_ADDR = "0xa88ca010b32a54d446fc38091ddbca55750cbfc3"; // Community WETH Prize Pool (Rari)
const WETH_POOL_TICKET_ADDR = "0x9b5c30aeb9ce2a6a121cea9a85bc0d662f6d9b40"; // Community WETH Prize Pool Ticket (Rari)

const prizePoolABI = [
  "function calculateEarlyExitFee( address from, address controlledToken, uint256 amount) external returns ( uint256 exitFee, uint256 burnedCredit)",
  "function creditPlanOf( address controlledToken) external view returns ( uint128 creditLimitMantissa, uint128 creditRateMantissa)",
];

const connectorsABI = [
  "function isConnectors(string[] calldata connectorNames) external view returns (bool, address[] memory)",
];

describe("PoolTogether", function() {
  const connectorName = "AAVEV2-TEST-A";
  const ptConnectorName = "POOLTOGETHER-TEST-A";

  let dsaWallet0: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;
  let ptConnector: Contract;

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;
  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: `https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
            blockNumber: 18717337,
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
      contractArtifact: ConnectV2AaveV2Polygon__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });

    // Deploy and enable Pool Together Connector
    ptConnector = await deployAndEnableConnector({
      connectorName: ptConnectorName,
      contractArtifact: ConnectV2PoolTogetherPolygon__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
  });

  it("Should have contracts deployed.", async function() {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!ptConnector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function() {
    it("Should build DSA v2", async function() {
      dsaWallet0 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit 1000 MATIC into DSA wallet", async function() {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("1000"),
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseEther("1000")
      );
    });
  });

  describe("Main - USDC Prize Pool Test", function() {
    it("Should deposit 100 MATIC in AAVE V2", async function() {
      const amount = ethers.utils.parseEther("100"); // 100 MATIC
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [tokens.eth.address, amount, 0, 0],
        },
      ];

      const tx = await dsaWallet0.cast(
        ...encodeSpells(spells),
        wallet1.address
      );
      const receipt = await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("900")
      );
    });

    it("Should borrow 10 USDC from AAVE V2 and deposit USDC into USDC Prize Pool", async function() {
      const amount = ethers.utils.parseUnits("10", 6); // 10 USDC
      const setId = "83478237";
      const spells = [
        {
          connector: connectorName,
          method: "borrow",
          args: [tokens.usdc.address, amount, 2, 0, setId],
        },
        {
          connector: ptConnectorName,
          method: "depositTo",
          args: [
            USDC_PRIZE_POOL_ADDR,
            amount,
            PT_USDC_SPONGSOR_TICKET_ADDR,
            setId,
            0,
          ],
        },
      ];
      // Before Spell
      let usdcToken = await ethers.getContractAt(
        abis.basic.erc20,
        tokens.usdc.address
      );
      let usdcBalance = await usdcToken.balanceOf(dsaWallet0.address);
      expect(usdcBalance, `USDC balance is 0`).to.be.eq(
        ethers.utils.parseUnits("0", 6)
      );

      let cToken = await ethers.getContractAt(
        abis.basic.erc20,
        PT_USDC_SPONGSOR_TICKET_ADDR
      );
      const balance = await cToken.balanceOf(dsaWallet0.address);
      expect(balance, `PoolTogether USDC Ticket balance is 0`).to.be.eq(0);

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After spell
      usdcBalance = await usdcToken.balanceOf(dsaWallet0.address);
      expect(
        usdcBalance,
        `Expect USDC balance to still equal 0 since it was deposited into Prize Pool`
      ).to.be.eq(0);

      const balanceAfter = await cToken.balanceOf(dsaWallet0.address);
      expect(
        balanceAfter,
        `PoolTogether USDC Ticket balance equals 10`
      ).to.be.eq(ethers.utils.parseUnits("10", 6));

      // ETH used for transaction
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("900")
      );
    });

    it("Should wait 11 days, withdraw all PrizePool, get back 10 USDC, and claim POOL", async function() {
      const amount = ethers.utils.parseUnits("10", 6); // 10 USDC

      let prizePoolContract = new ethers.Contract(
        USDC_PRIZE_POOL_ADDR,
        prizePoolABI,
        ethers.provider
      );
      // const { creditLimitMantissa, creditRateMantissa } = await prizePoolContract.creditPlanOf(PT_USDC_TICKET_ADDR);
      // console.log("CreditLimitMantiss: ", creditLimitMantissa.toString());
      // console.log("CreditRateMantiss: ", creditRateMantissa.toString());
      let earlyExitFee = await prizePoolContract.callStatic[
        "calculateEarlyExitFee"
      ](dsaWallet0.address, PT_USDC_SPONGSOR_TICKET_ADDR, amount);
      expect(
        earlyExitFee.exitFee,
        "Exit Fee equal to 0 USDC because 0% fee for sponsorship ticket"
      ).to.be.eq(ethers.utils.parseUnits("0", 6));

      const spells = [
        {
          connector: ptConnectorName,
          method: "claim",
          args: [USDC_POOL_FAUCET_ADDR, 0],
        },
        {
          connector: ptConnectorName,
          method: "withdrawInstantlyFrom",
          args: [
            USDC_PRIZE_POOL_ADDR,
            amount,
            PT_USDC_SPONGSOR_TICKET_ADDR,
            earlyExitFee.exitFee,
            0,
            0,
          ],
        },
      ];

      // Before spell
      let usdcToken = await ethers.getContractAt(
        abis.basic.erc20,
        tokens.usdc.address
      );
      let usdcBalance = await usdcToken.balanceOf(dsaWallet0.address);
      expect(usdcBalance, `USDC balance equals 0`).to.be.eq(
        ethers.utils.parseEther("0")
      );

      let cToken = await ethers.getContractAt(
        abis.basic.erc20,
        PT_USDC_SPONGSOR_TICKET_ADDR
      );
      const balance = await cToken.balanceOf(dsaWallet0.address);
      expect(balance, `PoolTogether USDC Ticket is 10`).to.be.eq(
        ethers.utils.parseUnits("10", 6)
      );

      let poolToken = await ethers.getContractAt(
        abis.basic.erc20,
        POOL_TOKEN_ADDRESS
      );
      const poolBalance = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalance, `POOL Token equals 0`).to.be.eq(
        ethers.utils.parseEther("0")
      );

      // Increase time by 11 days so we get back all USDC without early withdrawal fee
      await ethers.provider.send("evm_increaseTime", [15 * 24 * 60 * 60]);

      earlyExitFee = await prizePoolContract.callStatic[
        "calculateEarlyExitFee"
      ](dsaWallet0.address, PT_USDC_SPONGSOR_TICKET_ADDR, amount);
      expect(
        earlyExitFee.exitFee,
        "Exit Fee equal to 0 DAI because past 14 days"
      ).to.be.eq(0);

      // Run spell transaction
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      // After spell
      usdcBalance = await usdcToken.balanceOf(dsaWallet0.address);
      console.log("USDC BALANCE: ", usdcBalance.toString());
      console.log(
        "USDC BALANCE: ",
        ethers.utils.parseUnits("10", 6).toString()
      );
      expect(
        usdcBalance,
        `USDC balance to be equal to 10, because of no early withdrawal fee`
      ).to.be.eq(ethers.utils.parseUnits("10", 6));

      const balanceAfter = await cToken.balanceOf(dsaWallet0.address);
      expect(balanceAfter, `PoolTogether USDC Ticket to equal 0`).to.be.eq(0);

      const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address);
      console.log("POOL BALANCE AFTER:", poolBalanceAfter.toString());
      expect(
        poolBalanceAfter,
        `POOL Token Balance to be greater than 0`
      ).to.be.gt(ethers.utils.parseEther("0"));
    });

    it("Should deposit and withdraw all PrizePool, get back less than 10 USDC", async function() {
      const amount = ethers.utils.parseUnits("10", 6); // 10 USDC
      const exitFee = ethers.utils.parseUnits(".1", 6); // 1 USDC is 1% of 100 USDC
      const spells = [
        {
          connector: ptConnectorName,
          method: "depositTo",
          args: [USDC_PRIZE_POOL_ADDR, amount, PT_USDC_TICKET_ADDR, 0, 0],
        },
        {
          connector: ptConnectorName,
          method: "withdrawInstantlyFrom",
          args: [
            USDC_PRIZE_POOL_ADDR,
            amount,
            PT_USDC_TICKET_ADDR,
            exitFee,
            0,
            0,
          ],
        },
      ];

      // Before spell
      let usdcToken = await ethers.getContractAt(
        abis.basic.erc20,
        tokens.usdc.address
      );
      let usdcBalance = await usdcToken.balanceOf(dsaWallet0.address);
      expect(usdcBalance, `USDC Balance equals 100`).to.be.eq(
        ethers.utils.parseUnits("10", 6)
      );

      let cToken = await ethers.getContractAt(
        abis.basic.erc20,
        PT_USDC_TICKET_ADDR
      );
      const balance = await cToken.balanceOf(dsaWallet0.address);
      expect(balance, `PoolTogether USDC Ticket equals 0`).to.be.eq(0);

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
      usdcBalance = await usdcToken.balanceOf(dsaWallet0.address);
      expect(
        usdcBalance,
        `USDC balance to be less than 10, because of early withdrawal fee`
      ).to.be.lt(ethers.utils.parseUnits("10", 6));

      console.log("USDC BALANCE AFTER:", usdcBalance.toString());

      const balanceAfter = await cToken.balanceOf(dsaWallet0.address);
      expect(balanceAfter, `PoolTogether USDC Ticket to equal 0`).to.be.eq(0);

      const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address);
      expect(poolBalanceAfter, `POOL Token Balance to greater than 0`).to.be.gt(
        ethers.utils.parseEther("0")
      );
    });

    it("Should deposit, wait 11 days, and withdraw all PrizePool, get 10 USDC, and claim all POOL using claimAll", async function() {
      const amount = ethers.utils.parseUnits("9.9", 6); // 9 USDC
      const depositSpells = [
        {
          connector: ptConnectorName,
          method: "depositTo",
          args: [
            USDC_PRIZE_POOL_ADDR,
            amount,
            PT_USDC_SPONGSOR_TICKET_ADDR,
            0,
            0,
          ],
        },
      ];

      // Before spell
      let usdcToken = await ethers.getContractAt(
        abis.basic.erc20,
        tokens.usdc.address
      );
      let usdcBalance = await usdcToken.balanceOf(dsaWallet0.address);
      expect(usdcBalance, `USDC balance less than 10`).to.be.lt(
        ethers.utils.parseUnits("10", 6)
      );

      let cToken = await ethers.getContractAt(
        abis.basic.erc20,
        PT_USDC_SPONGSOR_TICKET_ADDR
      );
      const balance = await cToken.balanceOf(dsaWallet0.address);
      expect(balance, `PoolTogether USDC Ticket equal 0`).to.be.eq(0);

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
        USDC_PRIZE_POOL_ADDR,
        prizePoolABI,
        ethers.provider
      );
      let earlyExitFee = await prizePoolContract.callStatic[
        "calculateEarlyExitFee"
      ](dsaWallet0.address, PT_USDC_SPONGSOR_TICKET_ADDR, amount);
      expect(
        earlyExitFee.exitFee,
        "Exit Fee equal to 0 USDC because fee 0%"
      ).to.be.eq(0);

      // Increase time by 11 days so we get back all DAI without early withdrawal fee
      await ethers.provider.send("evm_increaseTime", [11 * 24 * 60 * 60]);

      const withdrawSpells = [
        {
          connector: ptConnectorName,
          method: "withdrawInstantlyFrom",
          args: [
            USDC_PRIZE_POOL_ADDR,
            amount,
            PT_USDC_SPONGSOR_TICKET_ADDR,
            earlyExitFee.exitFee,
            0,
            0,
          ],
        },
        {
          connector: ptConnectorName,
          method: "claimAll",
          args: [TOKEN_FAUCET_PROXY_FACTORY_ADDR, [USDC_POOL_FAUCET_ADDR]],
        },
      ];

      // Run spell transaction
      const tx2 = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(withdrawSpells), wallet1.address);
      const receipt2 = await tx2.wait();

      // After spell
      usdcBalance = await usdcToken.balanceOf(dsaWallet0.address);
      expect(usdcBalance, `USDC balance equals 9.9`).to.be.eq(
        ethers.utils.parseUnits("9.9", 6)
      );

      const balanceAfter = await cToken.balanceOf(dsaWallet0.address);
      expect(balanceAfter, `PoolTogether USDC Ticket equal 0`).to.be.eq(0);

      // Expect
      const poolBalanceAfter = await poolToken.balanceOf(dsaWallet0.address);
      console.log("POOL BALANCE AFTER:", poolBalanceAfter.toString());
      expect(poolBalanceAfter, `Pool Token to be greater than before`).to.be.gt(
        poolBalance
      );
    });
    // })

    // NO WMATIC POOLS: https://reference-app.pooltogether.com/pools/polygon
    //   describe("Main - WETH Prize Pool Test", function () {
    //     it("Deposit 1 ETH into WETH Prize Pool and withdraw immediately", async function () {
    //         const amount = ethers.utils.parseEther("1") // 1 ETH
    //         const setId = "83478237"
    //         const spells = [
    //             {
    //                 connector: ptConnectorName,
    //                 method: "depositTo",
    //                 args: [WETH_PRIZE_POOL_ADDR, amount, WETH_POOL_TICKET_ADDR, 0, setId]
    //             },
    //             {
    //                 connector: ptConnectorName,
    //                 method: "withdrawInstantlyFrom",
    //                 args: [WETH_PRIZE_POOL_ADDR, amount, WETH_POOL_TICKET_ADDR, amount, setId, 0]
    //             },
    //         ]
    //         // Before Spell
    //         const ethBalanceBefore = await ethers.provider.getBalance(dsaWallet0.address);

    //         // Run spell transaction
    //         const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)
    //         const receipt = await tx.wait()

    //         // After spell
    //         const ethBalanceAfter = await ethers.provider.getBalance(dsaWallet0.address);

    //         // ETH used for transaction
    //         expect(ethBalanceAfter, `ETH Balance less than before spell because of early withdrawal fee`).to.be.lte(ethBalanceBefore);
    //     });

    //     it("Deposit 1 ETH into WETH Prize Pool, wait 14 days, then withdraw", async function () {
    //         const amount = ethers.utils.parseEther("1") // 1 ETH
    //         const depositSpell = [
    //             {
    //                 connector: ptConnectorName,
    //                 method: "depositTo",
    //                 args: [WETH_PRIZE_POOL_ADDR, amount, WETH_POOL_TICKET_ADDR, 0, 0]
    //             }
    //         ]

    //         const withdrawSpell = [
    //             {
    //                 connector: ptConnectorName,
    //                 method: "withdrawInstantlyFrom",
    //                 args: [WETH_PRIZE_POOL_ADDR, amount, WETH_POOL_TICKET_ADDR, amount, 0, 0]
    //             }
    //         ]

    //         // Before Deposit Spell
    //         let ethBalanceBefore = await ethers.provider.getBalance(dsaWallet0.address);

    //         // Run deposit spell transaction
    //         const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(depositSpell), wallet1.address)
    //         const receipt = await tx.wait()

    //         // After Deposit spell
    //         let ethBalanceAfter = await ethers.provider.getBalance(dsaWallet0.address);

    //         expect(ethBalanceAfter, `ETH Balance less than before spell`).to.be.lte(ethBalanceBefore);

    //         // Increase time by 11 days so we get back all ETH without early withdrawal fee
    //         await ethers.provider.send("evm_increaseTime", [14*24*60*60]);
    //         await ethers.provider.send("evm_mine");

    //         // Run withdraw spell transaction
    //         const tx2 = await dsaWallet0.connect(wallet0).cast(...encodeSpells(withdrawSpell), wallet1.address)
    //         const receipt2 = await tx.wait()

    //         // After Deposit spell
    //         ethBalanceAfter = await ethers.provider.getBalance(dsaWallet0.address);

    //         expect(ethBalanceAfter, `ETH Balance equal to before spell because no early exit fee`).to.be.eq(ethBalanceBefore);
    //     });
  });
});
