const hre = require("hardhat");
const { expect } = require("chai");

// Instadapp deployment and testing helpers
const buildDSAv2 = require("../../scripts/buildDSAv2");
const encodeSpells = require("../../scripts/encodeSpells.js");

// Liquity smart contracts
const contracts = require("./liquity.contracts");

// Liquity helpers
const helpers = require("./liquity.helpers");

// Instadapp uses a fake address to represent native ETH
const { eth_addr: ETH_ADDRESS } = require("../../scripts/constant/constant");

describe.only("Liquity", () => {
  const { waffle, ethers } = hre;
  const { provider } = waffle;

  // Waffle test account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 (holds 1000 ETH)
  const wallet = provider.getWallets()[0];
  let dsa = null;
  let liquity = null;

  before(async () => {
    liquity = await helpers.deployAndConnect(contracts, true);
    expect(liquity.troveManager.address).to.exist;
    expect(liquity.borrowerOperations.address).to.exist;
    expect(liquity.stabilityPool.address).to.exist;
    expect(liquity.lusdToken.address).to.exist;
    expect(liquity.lqtyToken.address).to.exist;
    expect(liquity.activePool.address).to.exist;
    expect(liquity.priceFeed.address).to.exist;
    expect(liquity.hintHelpers.address).to.exist;
    expect(liquity.sortedTroves.address).to.exist;
    expect(liquity.staking.address).to.exist;
  });

  beforeEach(async () => {
    // Build a new DSA before each test so we start each test from the same default state
    dsa = await buildDSAv2(wallet.address);
    expect(dsa.address).to.exist;
  });

  describe("Main (Connector)", () => {
    describe("Trove", () => {
      describe("open()", () => {
        it("opens a Trove", async () => {
          const depositAmount = ethers.utils.parseEther("5"); // 5 ETH
          const borrowAmount = ethers.utils.parseUnits("2000", 18); // 2000 LUSD
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const originalUserBalance = await ethers.provider.getBalance(
            wallet.address
          );
          const originalDsaBalance = await ethers.provider.getBalance(
            dsa.address
          );

          const openTroveSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "open",
            args: [
              depositAmount,
              maxFeePercentage,
              borrowAmount,
              upperHint,
              lowerHint,
              0,
              0,
            ],
          };

          const tx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([openTroveSpell]), wallet.address, {
              value: depositAmount,
            });

          await tx.wait();

          const userBalance = await ethers.provider.getBalance(wallet.address);
          const dsaEthBalance = await ethers.provider.getBalance(dsa.address);
          const dsaLusdBalance = await liquity.lusdToken.balanceOf(dsa.address);
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );

          expect(userBalance).lt(
            originalUserBalance,
            "User should have less Ether after opening Trove"
          );

          expect(dsaEthBalance).to.eq(
            originalDsaBalance,
            "User's DSA account Ether should not change after borrowing"
          );

          expect(
            dsaLusdBalance,
            "DSA account should now hold the amount the user tried to borrow"
          ).to.eq(borrowAmount);

          expect(troveDebt).to.gt(
            borrowAmount,
            "Trove debt should equal the borrowed amount plus fee"
          );

          expect(troveCollateral).to.eq(
            depositAmount,
            "Trove collateral should equal the deposited amount"
          );
        });

        it("opens a Trove using ETH collected from a previous spell", async () => {
          const depositAmount = ethers.utils.parseEther("5"); // 5 ETH
          const borrowAmount = ethers.utils.parseUnits("2000", 18); // 2000 LUSD
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const originalUserBalance = await ethers.provider.getBalance(
            wallet.address
          );
          const originalDsaBalance = await ethers.provider.getBalance(
            dsa.address
          );
          const depositId = 1; // Choose an ID to store and retrieve the deopsited ETH

          const depositEthSpell = {
            connector: "Basic-v1",
            method: "deposit",
            args: [ETH_ADDRESS, depositAmount, 0, depositId],
          };

          const openTroveSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "open",
            args: [
              0, // When pulling ETH from a previous spell it doesn't matter what deposit value we put in this param
              maxFeePercentage,
              borrowAmount,
              upperHint,
              lowerHint,
              depositId,
              0,
            ],
          };

          const spells = [depositEthSpell, openTroveSpell];
          const tx = await dsa
            .connect(wallet)
            .cast(...encodeSpells(spells), wallet.address, {
              value: depositAmount,
            });

          await tx.wait();
          const userBalance = await ethers.provider.getBalance(wallet.address);
          const dsaEthBalance = await ethers.provider.getBalance(dsa.address);
          const dsaLusdBalance = await liquity.lusdToken.balanceOf(dsa.address);
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );

          expect(userBalance).lt(
            originalUserBalance,
            "User should have less Ether"
          );

          expect(dsaEthBalance).to.eq(
            originalDsaBalance,
            "DSA balance should not change"
          );

          expect(
            dsaLusdBalance,
            "DSA account should now hold the amount the user tried to borrow"
          ).to.eq(borrowAmount);

          expect(troveDebt).to.gt(
            borrowAmount,
            "Trove debt should equal the borrowed amount plus fee"
          );

          expect(troveCollateral).to.eq(
            depositAmount,
            "Trove collateral should equal the deposited amount"
          );
        });

        it("opens a Trove and stores the debt for other spells to use", async () => {
          const depositAmount = ethers.utils.parseEther("5"); // 5 ETH
          const borrowAmount = ethers.utils.parseUnits("2000", 18); // 2000 LUSD
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const originalUserBalance = await ethers.provider.getBalance(
            wallet.address
          );
          const originalDsaBalance = await ethers.provider.getBalance(
            dsa.address
          );
          const borrowId = 1;

          const openTroveSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "open",
            args: [
              depositAmount,
              maxFeePercentage,
              borrowAmount,
              upperHint,
              lowerHint,
              0,
              borrowId,
            ],
          };

          const withdrawLusdSpell = {
            connector: "Basic-v1",
            method: "withdraw",
            args: [
              contracts.LUSD_TOKEN_ADDRESS,
              0, // amount comes from the previous spell's setId
              dsa.address,
              borrowId,
              0,
            ],
          };

          const spells = [openTroveSpell, withdrawLusdSpell];
          const tx = await dsa
            .connect(wallet)
            .cast(...encodeSpells(spells), wallet.address, {
              value: depositAmount,
            });

          await tx.wait();

          const userBalance = await ethers.provider.getBalance(wallet.address);

          expect(userBalance).lt(
            originalUserBalance,
            "User should have less Ether after opening Trove"
          );

          const dsaEthBalance = await ethers.provider.getBalance(dsa.address);
          const dsaLusdBalance = await liquity.lusdToken.balanceOf(dsa.address);
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );

          expect(dsaEthBalance).to.eq(
            originalDsaBalance,
            "User's DSA account Ether should not change after borrowing"
          );

          expect(
            dsaLusdBalance,
            "DSA account should now hold the amount the user tried to borrow"
          ).to.eq(borrowAmount);

          expect(troveDebt).to.gt(
            borrowAmount,
            "Trove debt should equal the borrowed amount plus fee"
          );

          expect(troveCollateral).to.eq(
            depositAmount,
            "Trove collateral should equal the deposited amount"
          );
        });

        it("returns Instadapp event name and data", async () => {
          const depositAmount = ethers.utils.parseEther("5");
          const borrowAmount = ethers.utils.parseUnits("2000", 18);
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18);
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;

          const openTroveSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "open",
            args: [
              depositAmount,
              maxFeePercentage,
              borrowAmount,
              upperHint,
              lowerHint,
              0,
              0,
            ],
          };

          const openTx = await dsa.cast(
            ...encodeSpells([openTroveSpell]),
            wallet.address,
            {
              value: depositAmount,
            }
          );
          const receipt = await openTx.wait();
          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          expect(castLogEvent.eventNames[0]).eq(
            "LogOpen(address,uint256,uint256,uint256,uint256,uint256)"
          );
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256", "uint256", "uint256", "uint256"],
            [
              wallet.address,
              maxFeePercentage,
              depositAmount,
              borrowAmount,
              0,
              0,
            ]
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("close()", () => {
        it("closes a Trove", async () => {
          const depositAmount = ethers.utils.parseEther("5");
          const borrowAmount = ethers.utils.parseUnits("2000", 18);
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves,
            depositAmount,
            borrowAmount
          );

          const originalTroveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );

          const originalTroveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );

          // Send DSA account enough LUSD (from Stability Pool) to close their Trove
          const extraLusdRequiredToCloseTrove = originalTroveDebt.sub(
            borrowAmount
          );

          await helpers.sendToken(
            liquity.lusdToken,
            extraLusdRequiredToCloseTrove,
            contracts.STABILITY_POOL_ADDRESS,
            dsa.address
          );

          const originalDsaLusdBalance = await liquity.lusdToken.balanceOf(
            dsa.address
          );

          expect(
            originalDsaLusdBalance,
            "DSA account should now hold the LUSD amount required to pay off the Trove debt"
          ).to.eq(originalTroveDebt);

          const closeTroveSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "close",
            args: [0],
          };

          const closeTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([closeTroveSpell]), wallet.address);

          await closeTx.wait();
          const dsaEthBalance = await ethers.provider.getBalance(dsa.address);
          const dsaLusdBalance = await liquity.lusdToken.balanceOf(dsa.address);
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );

          expect(troveDebt, "Trove debt should equal 0 after close").to.eq(0);

          expect(
            troveCollateral,
            "Trove collateral should equal 0 after close"
          ).to.eq(0);

          expect(
            dsaEthBalance,
            "DSA account should now hold the Trove's ETH collateral"
          ).to.eq(originalTroveCollateral);

          expect(
            dsaLusdBalance,
            "DSA account should now hold the gas compensation amount of LUSD as it paid off the Trove debt"
          ).to.eq(helpers.LUSD_GAS_COMPENSATION);
        });

        it("closes a Trove using LUSD obtained from a previous spell", async () => {
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves
          );

          const originalTroveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const originalTroveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );

          // Send user enough LUSD to repay the loan, we'll use a deposit and withdraw spell to obtain it
          await helpers.sendToken(
            liquity.lusdToken,
            originalTroveDebt,
            contracts.STABILITY_POOL_ADDRESS,
            wallet.address
          );

          // Allow DSA to spend user's LUSD
          await liquity.lusdToken
            .connect(wallet)
            .approve(dsa.address, originalTroveDebt);

          const lusdDepositId = 1;

          // Simulate a spell which would have pulled LUSD from somewhere (e.g. AAVE) into InstaMemory
          // In this case we're simply running a deposit spell from the user's EOA
          const depositLusdSpell = {
            connector: "Basic-v1",
            method: "deposit",
            args: [
              contracts.LUSD_TOKEN_ADDRESS,
              originalTroveDebt,
              0,
              lusdDepositId,
            ],
          };
          // Withdraw the obtained LUSD into DSA account
          const withdrawLusdSpell = {
            connector: "Basic-v1",
            method: "withdraw",
            args: [
              contracts.LUSD_TOKEN_ADDRESS,
              0, // amount comes from the previous spell's setId
              dsa.address,
              lusdDepositId,
              0,
            ],
          };

          const closeTroveSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "close",
            args: [0],
          };

          const closeTx = await dsa
            .connect(wallet)
            .cast(
              ...encodeSpells([
                depositLusdSpell,
                withdrawLusdSpell,
                closeTroveSpell,
              ]),
              wallet.address
            );

          await closeTx.wait();
          const dsaEthBalance = await ethers.provider.getBalance(dsa.address);
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );

          expect(troveDebt, "Trove debt should equal 0 after close").to.eq(0);

          expect(
            troveCollateral,
            "Trove collateral should equal 0 after close"
          ).to.eq(0);

          expect(
            dsaEthBalance,
            "DSA account should now hold the Trove's ETH collateral"
          ).to.eq(originalTroveCollateral);
        });

        it("closes a Trove and stores the released collateral for other spells to use", async () => {
          const depositAmount = ethers.utils.parseEther("5");
          const borrowAmount = ethers.utils.parseUnits("2000", 18);
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves,
            depositAmount,
            borrowAmount
          );

          const originalTroveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const originalTroveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );

          // Send DSA account enough LUSD (from Stability Pool) to close their Trove
          const extraLusdRequiredToCloseTrove = originalTroveDebt.sub(
            borrowAmount
          );
          await helpers.sendToken(
            liquity.lusdToken,
            extraLusdRequiredToCloseTrove,
            contracts.STABILITY_POOL_ADDRESS,
            dsa.address
          );
          const originalDsaLusdBalance = await liquity.lusdToken.balanceOf(
            dsa.address
          );

          expect(
            originalDsaLusdBalance,
            "DSA account should now hold the LUSD amount required to pay off the Trove debt"
          ).to.eq(originalTroveDebt);

          const collateralWithdrawId = 1;

          const closeTroveSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "close",
            args: [collateralWithdrawId],
          };

          const withdrawEthSpell = {
            connector: "Basic-v1",
            method: "withdraw",
            args: [
              ETH_ADDRESS,
              0, // amount comes from the previous spell's setId
              dsa.address,
              collateralWithdrawId,
              0,
            ],
          };

          const closeTx = await dsa
            .connect(wallet)
            .cast(
              ...encodeSpells([closeTroveSpell, withdrawEthSpell]),
              wallet.address
            );

          await closeTx.wait();
          const dsaEthBalance = await ethers.provider.getBalance(dsa.address);
          const dsaLusdBalance = await liquity.lusdToken.balanceOf(dsa.address);
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );

          expect(troveDebt, "Trove debt should equal 0 after close").to.eq(0);

          expect(
            troveCollateral,
            "Trove collateral should equal 0 after close"
          ).to.eq(0);

          expect(
            dsaEthBalance,
            "DSA account should now hold the Trove's ETH collateral"
          ).to.eq(originalTroveCollateral);

          expect(
            dsaLusdBalance,
            "DSA account should now hold the gas compensation amount of LUSD as it paid off the Trove debt"
          ).to.eq(helpers.LUSD_GAS_COMPENSATION);
        });

        it("returns Instadapp event name and data", async () => {
          const depositAmount = ethers.utils.parseEther("5");
          const borrowAmount = ethers.utils.parseUnits("2000", 18);
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves,
            depositAmount,
            borrowAmount
          );
          await helpers.sendToken(
            liquity.lusdToken,
            ethers.utils.parseUnits("2500", 18),
            contracts.STABILITY_POOL_ADDRESS,
            dsa.address
          );

          const closeTroveSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "close",
            args: [0],
          };

          const closeTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([closeTroveSpell]), wallet.address);

          const receipt = await closeTx.wait();
          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256"],
            [wallet.address, 0]
          );
          expect(castLogEvent.eventNames[0]).eq("LogClose(address,uint256)");
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("deposit()", () => {
        it("deposits ETH into a Trove", async () => {
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves
          );

          const originalTroveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );

          const topupAmount = ethers.utils.parseEther("1");
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const depositEthSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "deposit",
            args: [topupAmount, upperHint, lowerHint, 0],
          };

          const depositTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([depositEthSpell]), wallet.address, {
              value: topupAmount,
            });

          await depositTx.wait();

          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );

          const expectedTroveCollateral = originalTroveCollateral.add(
            topupAmount
          );

          expect(
            troveCollateral,
            `Trove collateral should have increased by ${topupAmount} ETH`
          ).to.eq(expectedTroveCollateral);
        });

        it("returns Instadapp event name and data", async () => {
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves
          );

          const topupAmount = ethers.utils.parseEther("1");
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const depositEthSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "deposit",
            args: [topupAmount, upperHint, lowerHint, 0],
          };

          const depositTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([depositEthSpell]), wallet.address, {
              value: topupAmount,
            });

          const receipt = await depositTx.wait();
          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256"],
            [wallet.address, topupAmount, 0]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogDeposit(address,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("withdraw()", () => {
        it("withdraws ETH from a Trove", async () => {
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves
          );

          const originalTroveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );
          const withdrawAmount = ethers.utils.parseEther("1");
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const withdrawEthSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "withdraw",
            args: [withdrawAmount, upperHint, lowerHint, 0],
          };

          const withdrawTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([withdrawEthSpell]), wallet.address);

          await withdrawTx.wait();
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );
          const expectedTroveCollateral = originalTroveCollateral.sub(
            withdrawAmount
          );

          expect(
            troveCollateral,
            `Trove collateral should have decreased by ${withdrawAmount} ETH`
          ).to.eq(expectedTroveCollateral);
        });

        it("returns Instadapp event name and data", async () => {
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves
          );

          const withdrawAmount = ethers.utils.parseEther("1");
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const setId = 0;
          const withdrawEthSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "withdraw",
            args: [withdrawAmount, upperHint, lowerHint, setId],
          };

          const withdrawTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([withdrawEthSpell]), wallet.address);

          const receipt = await withdrawTx.wait();
          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256"],
            [wallet.address, withdrawAmount, setId]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogWithdraw(address,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("borrow()", () => {
        it("borrows LUSD from a Trove", async () => {
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves
          );

          const originalTroveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const borrowAmount = ethers.utils.parseUnits("1000", 18); // 1000 LUSD
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee
          const borrowSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "borrow",
            args: [maxFeePercentage, borrowAmount, upperHint, lowerHint, 0],
          };

          const borrowTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([borrowSpell]), wallet.address);

          await borrowTx.wait();
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const expectedTroveDebt = originalTroveDebt.add(borrowAmount);

          expect(
            troveDebt,
            `Trove debt should have increased by at least ${borrowAmount} ETH`
          ).to.gte(expectedTroveDebt);
        });

        it("returns Instadapp event name and data", async () => {
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves
          );

          const borrowAmount = ethers.utils.parseUnits("1000", 18); // 1000 LUSD
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee
          const setId = 0;
          const borrowSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "borrow",
            args: [maxFeePercentage, borrowAmount, upperHint, lowerHint, setId],
          };

          const borrowTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([borrowSpell]), wallet.address);

          const receipt = await borrowTx.wait();
          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256"],
            [wallet.address, borrowAmount, setId]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogBorrow(address,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("repay()", () => {
        it("repays LUSD to a Trove", async () => {
          const depositAmount = ethers.utils.parseEther("5");
          const borrowAmount = ethers.utils.parseUnits("2500", 18);

          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves,
            depositAmount,
            borrowAmount
          );

          const originalTroveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const repayAmount = ethers.utils.parseUnits("100", 18); // 100 LUSD
          const { upperHint, lowerHint } = await helpers.getTroveInsertionHints(
            depositAmount,
            borrowAmount,
            liquity.hintHelpers,
            liquity.sortedTroves
          );
          const borrowSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "repay",
            args: [repayAmount, upperHint, lowerHint, 0],
          };

          await dsa
            .connect(wallet)
            .cast(...encodeSpells([borrowSpell]), wallet.address, {
              value: repayAmount,
            });

          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const expectedTroveDebt = originalTroveDebt.sub(repayAmount);

          expect(
            troveDebt,
            `Trove debt should have decreased by ${repayAmount} ETH`
          ).to.eq(expectedTroveDebt);
        });

        it("returns Instadapp event name and data", async () => {
          const depositAmount = ethers.utils.parseEther("5");
          const borrowAmount = ethers.utils.parseUnits("2500", 18);
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves,
            depositAmount,
            borrowAmount
          );

          const repayAmount = ethers.utils.parseUnits("100", 18); // 100 LUSD
          const { upperHint, lowerHint } = await helpers.getTroveInsertionHints(
            depositAmount,
            borrowAmount,
            liquity.hintHelpers,
            liquity.sortedTroves
          );
          const getId = 0;

          const borrowSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "repay",
            args: [repayAmount, upperHint, lowerHint, getId],
          };

          const repayTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([borrowSpell]), wallet.address, {
              value: repayAmount,
            });

          const receipt = await repayTx.wait();
          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256"],
            [wallet.address, repayAmount, getId]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogRepay(address,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("adjust()", () => {
        it("adjusts a Trove: deposit ETH and borrow LUSD", async () => {
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves
          );

          const originalTroveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );
          const originalTroveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const depositAmount = ethers.utils.parseEther("1"); // 1 ETH
          const borrowAmount = ethers.utils.parseUnits("500", 18); // 500 LUSD
          const withdrawAmount = 0;
          const repayAmount = 0;
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee

          const adjustSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "adjust",
            args: [
              maxFeePercentage,
              withdrawAmount,
              depositAmount,
              borrowAmount,
              repayAmount,
              upperHint,
              lowerHint,
              0,
              0,
              0,
              0,
            ],
          };

          const adjustTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([adjustSpell]), wallet.address, {
              value: depositAmount,
              gasLimit: helpers.MAX_GAS,
            });

          await adjustTx.wait();
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const expectedTroveColl = originalTroveCollateral.add(depositAmount);
          const expectedTroveDebt = originalTroveDebt.add(borrowAmount);

          expect(
            troveCollateral,
            `Trove collateral should have increased by ${depositAmount} ETH`
          ).to.eq(expectedTroveColl);

          expect(
            troveDebt,
            `Trove debt should have increased by at least ${borrowAmount} ETH`
          ).to.gte(expectedTroveDebt);
        });

        it("adjusts a Trove: withdraw ETH and repay LUSD", async () => {
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves
          );

          const originalTroveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );
          const originalTroveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const depositAmount = 0;
          const borrowAmount = 0;
          const withdrawAmount = ethers.utils.parseEther("1"); // 1 ETH;
          const repayAmount = ethers.utils.parseUnits("500", 18); // 500 LUSD;
          const { upperHint, lowerHint } = await helpers.getTroveInsertionHints(
            originalTroveCollateral.sub(withdrawAmount),
            originalTroveDebt.sub(repayAmount),
            liquity.hintHelpers,
            liquity.sortedTroves
          );
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee

          const adjustSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "adjust",
            args: [
              maxFeePercentage,
              withdrawAmount,
              depositAmount,
              borrowAmount,
              repayAmount,
              upperHint,
              lowerHint,
              0,
              0,
              0,
              0,
            ],
          };

          const adjustTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([adjustSpell]), wallet.address, {
              value: depositAmount,
              gasLimit: helpers.MAX_GAS,
            });

          await adjustTx.wait();
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsa.address
          );
          const expectedTroveColl = originalTroveCollateral.sub(withdrawAmount);
          const expectedTroveDebt = originalTroveDebt.sub(repayAmount);

          expect(
            troveCollateral,
            `Trove collateral should have increased by ${depositAmount} ETH`
          ).to.eq(expectedTroveColl);

          expect(
            troveDebt,
            `Trove debt should have increased by at least ${borrowAmount} ETH`
          ).to.gte(expectedTroveDebt);
        });

        it("returns Instadapp event name and data", async () => {
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves
          );

          const depositAmount = ethers.utils.parseEther("1"); // 1 ETH
          const borrowAmount = ethers.utils.parseUnits("500", 18); // 500 LUSD
          const withdrawAmount = 0;
          const repayAmount = 0;
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee
          const getDepositId = 0;
          const setWithdrawId = 0;
          const getRepayId = 0;
          const setBorrowId = 0;

          const adjustSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "adjust",
            args: [
              maxFeePercentage,
              withdrawAmount,
              depositAmount,
              borrowAmount,
              repayAmount,
              upperHint,
              lowerHint,
              getDepositId,
              setWithdrawId,
              getRepayId,
              setBorrowId,
            ],
          };

          const adjustTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([adjustSpell]), wallet.address, {
              value: depositAmount,
              gasLimit: helpers.MAX_GAS,
            });

          const receipt = await adjustTx.wait();
          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            [
              "address",
              "uint256",
              "uint256",
              "uint256",
              "uint256",
              "uint256",
              "uint256",
              "uint256",
              "uint256",
              "uint256",
            ],
            [
              wallet.address,
              maxFeePercentage,
              depositAmount,
              withdrawAmount,
              borrowAmount,
              repayAmount,
              getDepositId,
              setWithdrawId,
              getRepayId,
              setBorrowId,
            ]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogAdjust(address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("claim()", () => {
        it("claims collateral from a redeemed Trove", async () => {
          // Create a low collateralized Trove
          const depositAmount = ethers.utils.parseEther("1.5");
          const borrowAmount = ethers.utils.parseUnits("2500", 18);

          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves,
            depositAmount,
            borrowAmount
          );

          // Redeem lots of LUSD to cause the Trove to become redeemed
          const redeemAmount = ethers.utils.parseUnits("10000000", 18);
          await helpers.sendToken(
            liquity.lusdToken,
            redeemAmount,
            contracts.STABILITY_POOL_ADDRESS,
            wallet.address
          );
          const {
            partialRedemptionHintNicr,
            firstRedemptionHint,
            upperHint,
            lowerHint,
          } = await helpers.getRedemptionHints(
            redeemAmount,
            liquity.hintHelpers,
            liquity.sortedTroves,
            liquity.priceFeed
          );
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee

          await liquity.troveManager
            .connect(wallet)
            .redeemCollateral(
              redeemAmount,
              firstRedemptionHint,
              upperHint,
              lowerHint,
              partialRedemptionHintNicr,
              0,
              maxFeePercentage,
              {
                gasLimit: helpers.MAX_GAS, // permit max gas
              }
            );

          const ethBalanceBefore = await ethers.provider.getBalance(
            dsa.address
          );

          // Claim the remaining collateral from the redeemed Trove
          const claimCollateralFromRedemptionSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "claimCollateralFromRedemption",
            args: [0],
          };

          const claimTx = await dsa
            .connect(wallet)
            .cast(
              ...encodeSpells([claimCollateralFromRedemptionSpell]),
              wallet.address
            );

          await claimTx.wait();

          const ethBalanceAfter = await ethers.provider.getBalance(dsa.address);

          const expectedRemainingCollateral = "527014573774047160"; // ~0.52 ETH based on this mainnet fork's blockNumber
          expect(ethBalanceAfter).to.be.gt(ethBalanceBefore);
          expect(ethBalanceAfter).to.eq(expectedRemainingCollateral);
        });

        it("returns Instadapp event name and data", async () => {
          // Create a low collateralized Trove
          const depositAmount = ethers.utils.parseEther("1.5");
          const borrowAmount = ethers.utils.parseUnits("2500", 18);

          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves,
            depositAmount,
            borrowAmount
          );

          // Redeem lots of LUSD to cause the Trove to become redeemed
          const redeemAmount = ethers.utils.parseUnits("10000000", 18);
          const setId = 0;
          await helpers.sendToken(
            liquity.lusdToken,
            redeemAmount,
            contracts.STABILITY_POOL_ADDRESS,
            wallet.address
          );
          const {
            partialRedemptionHintNicr,
            firstRedemptionHint,
            upperHint,
            lowerHint,
          } = await helpers.getRedemptionHints(
            redeemAmount,
            liquity.hintHelpers,
            liquity.sortedTroves,
            liquity.priceFeed
          );
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee

          await liquity.troveManager
            .connect(wallet)
            .redeemCollateral(
              redeemAmount,
              firstRedemptionHint,
              upperHint,
              lowerHint,
              partialRedemptionHintNicr,
              0,
              maxFeePercentage,
              {
                gasLimit: helpers.MAX_GAS, // permit max gas
              }
            );
          const claimAmount = await liquity.collSurplus.getCollateral(
            dsa.address
          );

          const claimCollateralFromRedemptionSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "claimCollateralFromRedemption",
            args: [setId],
          };

          const claimTx = await dsa
            .connect(wallet)
            .cast(
              ...encodeSpells([claimCollateralFromRedemptionSpell]),
              wallet.address
            );

          const receipt = await claimTx.wait();
          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256"],
            [wallet.address, claimAmount, setId]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogClaimCollateralFromRedemption(address,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });
    });

    describe("Stability Pool", () => {
      describe("stabilityDeposit()", () => {
        it("deposits into Stability Pool", async () => {
          const amount = ethers.utils.parseUnits("100", 18);
          const frontendTag = ethers.constants.AddressZero;

          await helpers.sendToken(
            liquity.lusdToken,
            amount,
            contracts.STABILITY_POOL_ADDRESS,
            dsa.address
          );

          const stabilityDepositSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stabilityDeposit",
            args: [amount, frontendTag, 0],
          };

          const depositTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([stabilityDepositSpell]), wallet.address);

          await depositTx.wait();
          const depositedAmount = await liquity.stabilityPool.getCompoundedLUSDDeposit(
            dsa.address
          );
          expect(depositedAmount).to.eq(amount);
        });

        it("returns Instadapp event name and data", async () => {
          const amount = ethers.utils.parseUnits("100", 18);
          const frontendTag = ethers.constants.AddressZero;
          const getId = 0;
          await helpers.sendToken(
            liquity.lusdToken,
            amount,
            contracts.STABILITY_POOL_ADDRESS,
            dsa.address
          );

          const stabilityDepositSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stabilityDeposit",
            args: [amount, frontendTag, getId],
          };

          const depositTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([stabilityDepositSpell]), wallet.address);

          const receipt = await depositTx.wait();
          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "address", "uint256"],
            [wallet.address, amount, frontendTag, getId]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogStabilityDeposit(address,uint256,address,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("stabilityWithdraw()", () => {
        it("withdraws from Stability Pool", async () => {
          // Start this test from scratch since we don't want to rely on test order for this to pass.
          [liquity, dsa] = await helpers.resetInitialState(
            wallet.address,
            contracts
          );

          // The current block number has liquidatable Troves.
          // Remove them otherwise Stability Pool withdrawals are disabled
          await liquity.troveManager.connect(wallet).liquidateTroves(90, {
            gasLimit: helpers.MAX_GAS,
          });
          const amount = ethers.utils.parseUnits("100", 18);
          const frontendTag = ethers.constants.AddressZero;

          await helpers.sendToken(
            liquity.lusdToken,
            amount,
            contracts.STABILITY_POOL_ADDRESS,
            dsa.address
          );

          const stabilityDepositSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stabilityDeposit",
            args: [amount, frontendTag, 0],
          };

          // Withdraw half of the deposit
          const stabilitWithdrawSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stabilityWithdraw",
            args: [amount.div(2), 0],
          };
          const spells = [stabilityDepositSpell, stabilitWithdrawSpell];

          const castTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells(spells), wallet.address);

          await castTx.wait();

          const depositedAmount = await liquity.stabilityPool.getCompoundedLUSDDeposit(
            dsa.address
          );
          const dsaLusdBalance = await liquity.lusdToken.balanceOf(dsa.address);

          expect(depositedAmount).to.eq(amount.div(2));
          expect(dsaLusdBalance).to.eq(amount.div(2));
        });

        it("returns Instadapp event name and data", async () => {
          // Start this test from scratch since we don't want to rely on test order for this to pass.
          [liquity, dsa] = await helpers.resetInitialState(
            wallet.address,
            contracts
          );

          // The current block number has liquidatable Troves.
          // Remove them otherwise Stability Pool withdrawals are disabled
          await liquity.troveManager.connect(wallet).liquidateTroves(90, {
            gasLimit: helpers.MAX_GAS,
          });
          const amount = ethers.utils.parseUnits("100", 18);
          const frontendTag = ethers.constants.AddressZero;
          const setId = 0;

          await helpers.sendToken(
            liquity.lusdToken,
            amount,
            contracts.STABILITY_POOL_ADDRESS,
            dsa.address
          );

          const stabilityDepositSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stabilityDeposit",
            args: [amount, frontendTag, setId],
          };

          // Withdraw half of the deposit
          const withdrawAmount = amount.div(2);
          const stabilitWithdrawSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stabilityWithdraw",
            args: [withdrawAmount, 0],
          };
          const spells = [stabilityDepositSpell, stabilitWithdrawSpell];

          const castTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells(spells), wallet.address);

          const receipt = await castTx.wait();
          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256"],
            [wallet.address, withdrawAmount, setId]
          );
          expect(castLogEvent.eventNames[1]).eq(
            "LogStabilityWithdraw(address,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[1]).eq(expectedEventParams);
        });
      });

      describe("stabilityMoveEthGainToTrove()", () => {
        beforeEach(async () => {
          // Start these test from fresh so that we definitely have a liquidatable Trove within this block
          [liquity, dsa] = await helpers.resetInitialState(
            wallet.address,
            contracts
          );
        });

        it("moves ETH gain from Stability Pool to Trove", async () => {
          // Create a DSA owned Trove to capture ETH liquidation gains
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves
          );
          const troveCollateralBefore = await liquity.troveManager.getTroveColl(
            dsa.address
          );

          // Create a Stability Deposit using the Trove's borrowed LUSD
          const amount = ethers.utils.parseUnits("100", 18);
          const frontendTag = ethers.constants.AddressZero;
          const stabilityDepositSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stabilityDeposit",
            args: [amount, frontendTag, 0],
          };

          const depositTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([stabilityDepositSpell]), wallet.address);

          await depositTx.wait();

          // Liquidate a Trove to create an ETH gain for the new DSA Trove
          await liquity.troveManager
            .connect(wallet)
            .liquidate(helpers.LIQUIDATABLE_TROVE_ADDRESS, {
              gasLimit: helpers.MAX_GAS, // permit max gas
            });

          const ethGainFromLiquidation = await liquity.stabilityPool.getDepositorETHGain(
            dsa.address
          );

          // Move ETH gain to Trove
          const moveEthGainSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stabilityMoveEthGainToTrove",
            args: [ethers.constants.AddressZero, ethers.constants.AddressZero],
          };

          const moveEthGainTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([moveEthGainSpell]), wallet.address);

          await moveEthGainTx.wait();

          const ethGainAfterMove = await liquity.stabilityPool.getDepositorETHGain(
            dsa.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsa.address
          );
          const expectedTroveCollateral = troveCollateralBefore.add(
            ethGainFromLiquidation
          );
          expect(ethGainAfterMove).to.eq(0);
          expect(troveCollateral).to.eq(expectedTroveCollateral);
        });

        it("returns Instadapp event name and data", async () => {
          // Create a DSA owned Trove to capture ETH liquidation gains
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liquity.hintHelpers,
            liquity.sortedTroves
          );

          // Create a Stability Deposit using the Trove's borrowed LUSD
          const amount = ethers.utils.parseUnits("100", 18);
          const frontendTag = ethers.constants.AddressZero;
          const stabilityDepositSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stabilityDeposit",
            args: [amount, frontendTag, 0],
          };

          const depositTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([stabilityDepositSpell]), wallet.address);

          await depositTx.wait();

          // Liquidate a Trove to create an ETH gain for the new DSA Trove
          await liquity.troveManager
            .connect(wallet)
            .liquidate(helpers.LIQUIDATABLE_TROVE_ADDRESS, {
              gasLimit: helpers.MAX_GAS, // permit max gas
            });

          const ethGainFromLiquidation = await liquity.stabilityPool.getDepositorETHGain(
            dsa.address
          );

          // Move ETH gain to Trove
          const moveEthGainSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stabilityMoveEthGainToTrove",
            args: [ethers.constants.AddressZero, ethers.constants.AddressZero],
          };

          const moveEthGainTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([moveEthGainSpell]), wallet.address);

          const receipt = await moveEthGainTx.wait();

          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256"],
            [wallet.address, ethGainFromLiquidation]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogStabilityMoveEthGainToTrove(address,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });
    });

    describe("Staking", () => {
      describe("stake()", () => {
        it("stakes LQTY", async () => {
          const totalStakingBalanceBefore = await liquity.lqtyToken.balanceOf(
            contracts.STAKING_ADDRESS
          );

          const amount = ethers.utils.parseUnits("1", 18);
          await helpers.sendToken(
            liquity.lqtyToken,
            amount,
            helpers.JUSTIN_SUN_ADDRESS,
            dsa.address
          );

          const stakeSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stake",
            args: [amount, 0],
          };

          const stakeTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([stakeSpell]), wallet.address);

          await stakeTx.wait();

          const lqtyBalance = await liquity.lqtyToken.balanceOf(dsa.address);
          expect(lqtyBalance).to.eq(0);

          const totalStakingBalance = await liquity.lqtyToken.balanceOf(
            contracts.STAKING_ADDRESS
          );
          expect(totalStakingBalance).to.eq(
            totalStakingBalanceBefore.add(amount)
          );
        });

        it("returns Instadapp event name and data", async () => {
          const amount = ethers.utils.parseUnits("1", 18);
          await helpers.sendToken(
            liquity.lqtyToken,
            amount,
            helpers.JUSTIN_SUN_ADDRESS,
            dsa.address
          );
          const getId = 0;

          const stakeSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stake",
            args: [amount, getId],
          };

          const stakeTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([stakeSpell]), wallet.address);

          const receipt = await stakeTx.wait();

          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256"],
            [wallet.address, amount, getId]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogStake(address,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("unstake()", () => {
        it("unstakes LQTY", async () => {
          const amount = ethers.utils.parseUnits("1", 18);
          await helpers.sendToken(
            liquity.lqtyToken,
            amount,
            helpers.JUSTIN_SUN_ADDRESS,
            dsa.address
          );

          const stakeSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stake",
            args: [amount, 0],
          };

          const stakeTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([stakeSpell]), wallet.address);

          await stakeTx.wait();

          const totalStakingBalanceBefore = await liquity.lqtyToken.balanceOf(
            contracts.STAKING_ADDRESS
          );

          const unstakeSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "unstake",
            args: [amount, 0],
          };

          const unstakeTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([unstakeSpell]), wallet.address);

          await unstakeTx.wait();

          const lqtyBalance = await liquity.lqtyToken.balanceOf(dsa.address);
          expect(lqtyBalance).to.eq(amount);

          const totalStakingBalance = await liquity.lqtyToken.balanceOf(
            contracts.STAKING_ADDRESS
          );
          expect(totalStakingBalance).to.eq(
            totalStakingBalanceBefore.sub(amount)
          );
        });

        it("returns Instadapp event name and data", async () => {
          const amount = ethers.utils.parseUnits("1", 18);
          await helpers.sendToken(
            liquity.lqtyToken,
            amount,
            helpers.JUSTIN_SUN_ADDRESS,
            dsa.address
          );

          const stakeSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "stake",
            args: [amount, 0],
          };

          await dsa
            .connect(wallet)
            .cast(...encodeSpells([stakeSpell]), wallet.address);

          const setId = 0;
          const unstakeSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "unstake",
            args: [amount, setId],
          };

          const unstakeTx = await dsa
            .connect(wallet)
            .cast(...encodeSpells([unstakeSpell]), wallet.address);

          const receipt = await unstakeTx.wait();

          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256"],
            [wallet.address, amount, setId]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogUnstake(address,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe.skip("claimStakingGains()", () => {
        it("Claims gains from staking", async () => {});

        it("returns Instadapp event name and data", async () => {
          const stakerDsa = await buildDSAv2(wallet.address);
          const whaleLqtyBalance = await liquity.lqtyToken.balanceOf(
            helpers.JUSTIN_SUN_ADDRESS
          );
          console.log("BALANCE", whaleLqtyBalance.toString());

          // Stake lots of LQTY
          await helpers.sendToken(
            liquity.lqtyToken,
            whaleLqtyBalance,
            helpers.JUSTIN_SUN_ADDRESS,
            stakerDsa.address
          );
          const dsaBalance = await liquity.lqtyToken.balanceOf(
            stakerDsa.address
          );
          console.log("dsaBalance", dsaBalance.toString());
          await liquity.staking
            .connect(stakerDsa.signer)
            .stake(ethers.utils.parseUnits("1", 18));

          // Open a Trove to cause an ETH issuance gain for stakers
          await helpers.createDsaTrove(
            dsa,
            wallet,
            liqiuty.hintHelpers,
            liquity.sortedTroves
          );

          // Redeem some ETH to cause an LUSD redemption gain for stakers
          await helpers.redeem(
            ethers.utils.parseUnits("1000", 18),
            contracts.STABILITY_POOL_ADDRESS,
            wallet.address,
            liquity
          );

          const setEthGainId = 0;
          const setLusdGainId = 0;
          const claimStakingGainsSpell = {
            connector: helpers.CONNECTOR_NAME,
            method: "claimStakingGains",
            args: [setEthGainId, setLusdGainId],
          };

          const claimGainsTx = await stakerDsa
            .connect(wallet)
            .cast(...encodeSpells([claimStakingGainsSpell]), wallet.address);

          const receipt = await claimGainsTx.wait();

          const castLogEvent = receipt.events.find((e) => e.event === "LogCast")
            .args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256"],
            [helpers.JUSTIN_SUN_ADDRESS, setEthGainId, setLusdGainId]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogClaimStakingGains(address,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });
    });
  });
});
