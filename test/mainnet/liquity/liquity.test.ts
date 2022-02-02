import hre from "hardhat";
import { expect } from "chai";

// Instadapp deployment and testing helpers
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";

// Liquity smart contracts
import contracts from "./liquity.contracts";

// Liquity helpers
import helpers from "./liquity.helpers";

describe("Liquity", () => {
  const { waffle, ethers } = hre;
  const { provider } = waffle;
  let userWallet: any;
  // Waffle test account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 (holds 1000 ETH)
  let dsaWallet0: any;
  let liquity: any;

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
    userWallet = provider.getWallets()[0];
    // Build a new DSA before each test so we start each test from the same default state
    dsaWallet0 = await buildDSAv2(userWallet.address);
    expect(dsaWallet0.address).to.exist;
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
            userWallet.address
          );
          const originalDsaBalance = await ethers.provider.getBalance(
            dsaWallet0.address
          );

          const openTroveSpell = [
            {
              connector: helpers.LIQUITY_CONNECTOR,
              method: "open",
              args: [
                depositAmount,
                maxFeePercentage,
                borrowAmount,
                upperHint,
                lowerHint,
                [0, 0],
                [0, 0],
              ],
            },
          ];

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(openTroveSpell), userWallet.address, {
              value: depositAmount,
            });

          const userBalance = await ethers.provider.getBalance(
            userWallet.address
          );
          const dsaEthBalance = await ethers.provider.getBalance(
            dsaWallet0.address
          );
          const dsaLusdBalance = await liquity.lusdToken.balanceOf(
            dsaWallet0.address
          );
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          expect(userBalance).lt(
            originalUserBalance.sub(depositAmount),
            "User's Ether balance should decrease"
          );

          expect(dsaEthBalance).to.eq(
            originalDsaBalance,
            "User's DSA account Ether should not change after borrowing"
          );

          expect(
            dsaLusdBalance,
            "DSA account should now hold the amount the user borrowed"
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
            userWallet.address
          );
          const originalDsaBalance = await ethers.provider.getBalance(
            dsaWallet0.address
          );
          const depositId = 1; // Choose an ID to store and retrieve the deposited ETH

          const depositEthSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "deposit",
            args: [helpers.ETH, depositAmount, 0, depositId],
          };

          const openTroveSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "open",
            args: [
              0, // When pulling ETH from a previous spell it doesn't matter what deposit value we put in this param
              maxFeePercentage,
              borrowAmount,
              upperHint,
              lowerHint,
              [depositId, 0],
              [0, 0],
            ],
          };

          const spells = [depositEthSpell, openTroveSpell];
          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address, {
              value: depositAmount,
            });

          const userBalance = await ethers.provider.getBalance(
            userWallet.address
          );
          const dsaEthBalance = await ethers.provider.getBalance(
            dsaWallet0.address
          );
          const dsaLusdBalance = await liquity.lusdToken.balanceOf(
            dsaWallet0.address
          );
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          expect(userBalance).lt(
            originalUserBalance.sub(depositAmount),
            "User's Ether balance should decrease by the amount they deposited"
          );

          expect(dsaEthBalance).to.eq(
            originalDsaBalance,
            "DSA balance should not change"
          );

          expect(
            dsaLusdBalance,
            "DSA account should now hold the amount the user borrowed"
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
            userWallet.address
          );
          const originalDsaBalance = await ethers.provider.getBalance(
            dsaWallet0.address
          );
          const borrowId = 1;

          const openTroveSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "open",
            args: [
              depositAmount,
              maxFeePercentage,
              borrowAmount,
              upperHint,
              lowerHint,
              [0, 0],
              [borrowId, 0],
            ],
          };

          const withdrawLusdSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "withdraw",
            args: [
              contracts.LUSD_TOKEN_ADDRESS,
              0, // Amount comes from the previous spell's setId
              dsaWallet0.address,
              borrowId,
              0,
            ],
          };

          const spells = [openTroveSpell, withdrawLusdSpell];
          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address, {
              value: depositAmount,
            });

          const userBalance = await ethers.provider.getBalance(
            userWallet.address
          );
          const dsaEthBalance = await ethers.provider.getBalance(
            dsaWallet0.address
          );
          const dsaLusdBalance = await liquity.lusdToken.balanceOf(
            dsaWallet0.address
          );
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          expect(userBalance).lt(
            originalUserBalance.sub(depositAmount),
            "User's Ether balance should decrease by the amount they deposited"
          );

          expect(dsaEthBalance).to.eq(
            originalDsaBalance,
            "User's DSA account Ether should not change after borrowing"
          );

          expect(
            dsaLusdBalance,
            "DSA account should now hold the amount the user borrowed"
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
            connector: helpers.LIQUITY_CONNECTOR,
            method: "open",
            args: [
              depositAmount,
              maxFeePercentage,
              borrowAmount,
              upperHint,
              lowerHint,
              [0, 0],
              [0, 0],
            ],
          };

          const openTx = await dsaWallet0.cast(
            ...encodeSpells([openTroveSpell]),
            userWallet.address,
            {
              value: depositAmount,
            }
          );
          const receipt = await openTx.wait();
          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
          expect(castLogEvent.eventNames[0]).eq(
            "LogOpen(address,uint256,uint256,uint256,uint256[],uint256[])"
          );
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            [
              "address",
              "uint256",
              "uint256",
              "uint256",
              "uint256[]",
              "uint256[]",
            ],
            [
              dsaWallet0.address,
              maxFeePercentage,
              depositAmount,
              borrowAmount,
              [0, 0],
              [0, 0],
            ]
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("close()", () => {
        it("closes a Trove", async () => {
          const depositAmount = ethers.utils.parseEther("5");
          const borrowAmount = ethers.utils.parseUnits("2000", 18);
          // Create a dummy Trove
          await helpers.createDsaTrove(
            dsaWallet0,
            userWallet,
            liquity,
            depositAmount,
            borrowAmount
          );

          const troveDebtBefore = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );

          const troveCollateralBefore = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          // Send DSA account enough LUSD (from Stability Pool) to close their Trove
          const extraLusdRequiredToCloseTrove = troveDebtBefore.sub(
            borrowAmount
          );

          await helpers.sendToken(
            liquity.lusdToken,
            extraLusdRequiredToCloseTrove,
            contracts.STABILITY_POOL_ADDRESS,
            dsaWallet0.address
          );

          const originalDsaLusdBalance = await liquity.lusdToken.balanceOf(
            dsaWallet0.address
          );

          expect(
            originalDsaLusdBalance,
            "DSA account should now hold the LUSD amount required to pay off the Trove debt"
          ).to.eq(troveDebtBefore);

          const closeTroveSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "close",
            args: [0],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([closeTroveSpell]), userWallet.address);

          const dsaEthBalance = await ethers.provider.getBalance(
            dsaWallet0.address
          );
          const dsaLusdBalance = await liquity.lusdToken.balanceOf(
            dsaWallet0.address
          );
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          expect(troveDebt, "Trove debt should equal 0 after close").to.eq(0);

          expect(
            troveCollateral,
            "Trove collateral should equal 0 after close"
          ).to.eq(0);

          expect(
            dsaEthBalance,
            "DSA account should now hold the Trove's ETH collateral"
          ).to.eq(troveCollateralBefore);

          expect(
            dsaLusdBalance,
            "DSA account should now hold the gas compensation amount of LUSD as it paid off the Trove debt"
          ).to.eq(helpers.LUSD_GAS_COMPENSATION);
        });

        it("closes a Trove using LUSD obtained from a previous spell", async () => {
          // Create a dummy Trove
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const troveDebtBefore = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const troveCollateralBefore = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          // Send user enough LUSD to repay the loan, we'll use a deposit and withdraw spell to obtain it
          await helpers.sendToken(
            liquity.lusdToken,
            troveDebtBefore,
            contracts.STABILITY_POOL_ADDRESS,
            userWallet.address
          );

          // Allow DSA to spend user's LUSD
          await liquity.lusdToken
            .connect(userWallet)
            .approve(dsaWallet0.address, troveDebtBefore);

          // Simulate a spell which would have pulled LUSD from somewhere (e.g. Uniswap) into InstaMemory
          // In this case we're simply running a deposit spell from the user's EOA
          const depositLusdSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "deposit",
            args: [contracts.LUSD_TOKEN_ADDRESS, troveDebtBefore, 0, 0],
          };

          const closeTroveSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "close",
            args: [0],
          };
          const spells = [depositLusdSpell, closeTroveSpell];

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address);

          const dsaEthBalance = await ethers.provider.getBalance(
            dsaWallet0.address
          );
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          expect(troveDebt, "Trove debt should equal 0 after close").to.eq(0);

          expect(
            troveCollateral,
            "Trove collateral should equal 0 after close"
          ).to.eq(0);

          expect(
            dsaEthBalance,
            "DSA account should now hold the Trove's ETH collateral"
          ).to.eq(troveCollateralBefore);
        });

        it("closes a Trove and stores the released collateral for other spells to use", async () => {
          const depositAmount = ethers.utils.parseEther("5");
          const borrowAmount = ethers.utils.parseUnits("2000", 18);
          // Create a dummy Trove
          await helpers.createDsaTrove(
            dsaWallet0,
            userWallet,
            liquity,
            depositAmount,
            borrowAmount
          );

          const troveDebtBefore = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const troveCollateralBefore = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          // Send DSA account enough LUSD (from Stability Pool) to close their Trove
          const extraLusdRequiredToCloseTrove = troveDebtBefore.sub(
            borrowAmount
          );
          await helpers.sendToken(
            liquity.lusdToken,
            extraLusdRequiredToCloseTrove,
            contracts.STABILITY_POOL_ADDRESS,
            dsaWallet0.address
          );
          const originalDsaLusdBalance = await liquity.lusdToken.balanceOf(
            dsaWallet0.address
          );

          expect(
            originalDsaLusdBalance,
            "DSA account should now hold the LUSD amount required to pay off the Trove debt"
          ).to.eq(troveDebtBefore);

          const collateralWithdrawId = 1;

          const closeTroveSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "close",
            args: [collateralWithdrawId],
          };

          const withdrawEthSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "withdraw",
            args: [
              helpers.ETH,
              0, // amount comes from the previous spell's setId
              dsaWallet0.address,
              collateralWithdrawId,
              0,
            ],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(
              ...encodeSpells([closeTroveSpell, withdrawEthSpell]),
              userWallet.address
            );

          const dsaEthBalance = await ethers.provider.getBalance(
            dsaWallet0.address
          );
          const dsaLusdBalance = await liquity.lusdToken.balanceOf(
            dsaWallet0.address
          );
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          expect(troveDebt, "Trove debt should equal 0 after close").to.eq(0);

          expect(
            troveCollateral,
            "Trove collateral should equal 0 after close"
          ).to.eq(0);

          expect(
            dsaEthBalance,
            "DSA account should now hold the Trove's ETH collateral"
          ).to.eq(troveCollateralBefore);

          expect(
            dsaLusdBalance,
            "DSA account should now hold the gas compensation amount of LUSD as it paid off the Trove debt"
          ).to.eq(helpers.LUSD_GAS_COMPENSATION);
        });

        it("returns Instadapp event name and data", async () => {
          const depositAmount = ethers.utils.parseEther("5");
          const borrowAmount = ethers.utils.parseUnits("2000", 18);
          // Create a dummy Trove
          await helpers.createDsaTrove(
            dsaWallet0,
            userWallet,
            liquity,
            depositAmount,
            borrowAmount
          );
          await helpers.sendToken(
            liquity.lusdToken,
            ethers.utils.parseUnits("2500", 18),
            contracts.STABILITY_POOL_ADDRESS,
            dsaWallet0.address
          );

          const closeTroveSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "close",
            args: [0],
          };

          const closeTx = await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([closeTroveSpell]), userWallet.address);

          const receipt = await closeTx.wait();
          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256"],
            [dsaWallet0.address, 0]
          );
          expect(castLogEvent.eventNames[0]).eq("LogClose(address,uint256)");
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("deposit()", () => {
        it("deposits ETH into a Trove", async () => {
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const troveCollateralBefore = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          const topupAmount = ethers.utils.parseEther("1");
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const depositEthSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "deposit",
            args: [topupAmount, upperHint, lowerHint, 0, 0],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([depositEthSpell]), userWallet.address, {
              value: topupAmount,
            });

          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          const expectedTroveCollateral = troveCollateralBefore.add(
            topupAmount
          );

          expect(
            troveCollateral,
            `Trove collateral should have increased by ${topupAmount} ETH`
          ).to.eq(expectedTroveCollateral);
        });

        it("deposits using ETH gained from a previous spell", async () => {
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);
          const troveCollateralBefore = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          const topupAmount = ethers.utils.parseEther("1");
          const depositId = 1;
          const depositEthSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "deposit",
            args: [helpers.ETH, topupAmount, 0, depositId],
          };

          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const depositEthToTroveSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "deposit",
            args: [0, upperHint, lowerHint, depositId, 0],
          };
          const spells = [depositEthSpell, depositEthToTroveSpell];

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address, {
              value: topupAmount,
            });

          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          const expectedTroveCollateral = troveCollateralBefore.add(
            topupAmount
          );

          expect(
            troveCollateral,
            `Trove collateral should have increased by ${topupAmount} ETH`
          ).to.eq(expectedTroveCollateral);
        });

        it("returns Instadapp event name and data", async () => {
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const topupAmount = ethers.utils.parseEther("1");
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const depositEthSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "deposit",
            args: [topupAmount, upperHint, lowerHint, 0, 0],
          };

          const depositTx = await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([depositEthSpell]), userWallet.address, {
              value: topupAmount,
            });

          const receipt = await depositTx.wait();
          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256", "uint256"],
            [dsaWallet0.address, topupAmount, 0, 0]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogDeposit(address,uint256,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("withdraw()", () => {
        it("withdraws ETH from a Trove", async () => {
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const troveCollateralBefore = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );
          const withdrawAmount = ethers.utils.parseEther("1");
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const withdrawEthSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "withdraw",
            args: [withdrawAmount, upperHint, lowerHint, 0, 0],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([withdrawEthSpell]), userWallet.address);

          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );
          const expectedTroveCollateral = troveCollateralBefore.sub(
            withdrawAmount
          );

          expect(
            troveCollateral,
            `Trove collateral should have decreased by ${withdrawAmount} ETH`
          ).to.eq(expectedTroveCollateral);
        });

        it("withdraws ETH from a Trove and stores the ETH for other spells to use", async () => {
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const troveCollateralBefore = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );
          const originalUserEthBalance = await ethers.provider.getBalance(
            userWallet.address
          );

          const withdrawAmount = ethers.utils.parseEther("1");
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const withdrawId = 1;
          const withdrawEthFromTroveSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "withdraw",
            args: [withdrawAmount, upperHint, lowerHint, 0, withdrawId],
          };

          const withdrawEthSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "withdraw",
            args: [helpers.ETH, 0, userWallet.address, withdrawId, 0],
          };
          const spells = [withdrawEthFromTroveSpell, withdrawEthSpell];
          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address);

          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );
          const expectedTroveCollateral = troveCollateralBefore.sub(
            withdrawAmount
          );
          const userEthBalance = await ethers.provider.getBalance(
            userWallet.address
          );

          expect(
            troveCollateral,
            `Trove collateral should have decreased by ${withdrawAmount} ETH`
          ).to.eq(expectedTroveCollateral);

          expect(
            userEthBalance,
            `User ETH balance should have increased by ${withdrawAmount} ETH`
          ).to.lt(originalUserEthBalance.add(withdrawAmount));
        });

        it("returns Instadapp event name and data", async () => {
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const withdrawAmount = ethers.utils.parseEther("1");
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const withdrawEthSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "withdraw",
            args: [withdrawAmount, upperHint, lowerHint, 0, 0],
          };

          const withdrawTx = await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([withdrawEthSpell]), userWallet.address);

          const receipt = await withdrawTx.wait();
          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256", "uint256"],
            [dsaWallet0.address, withdrawAmount, 0, 0]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogWithdraw(address,uint256,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("borrow()", () => {
        it("borrows LUSD from a Trove", async () => {
          // Create a dummy Trove
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const troveDebtBefore = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );

          const borrowAmount = ethers.utils.parseUnits("1000", 18); // 1000 LUSD
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee
          const borrowSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "borrow",
            args: [maxFeePercentage, borrowAmount, upperHint, lowerHint, 0, 0],
          };

          // Borrow more LUSD from the Trove
          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([borrowSpell]), userWallet.address);

          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const expectedTroveDebt = troveDebtBefore.add(borrowAmount);

          expect(
            troveDebt,
            `Trove debt should have increased by at least ${borrowAmount} ETH`
          ).to.gte(expectedTroveDebt);
        });

        it("borrows LUSD from a Trove and stores the LUSD for other spells to use", async () => {
          // Create a dummy Trove
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const troveDebtBefore = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );

          const borrowAmount = ethers.utils.parseUnits("1000", 18); // 1000 LUSD
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee
          const borrowId = 1;
          const borrowSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "borrow",
            args: [
              maxFeePercentage,
              borrowAmount,
              upperHint,
              lowerHint,
              0,
              borrowId,
            ],
          };
          const withdrawSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "withdraw",
            args: [
              liquity.lusdToken.address,
              0,
              userWallet.address,
              borrowId,
              0,
            ],
          };
          const spells = [borrowSpell, withdrawSpell];

          // Borrow more LUSD from the Trove
          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address);

          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const expectedTroveDebt = troveDebtBefore.add(borrowAmount);
          const userLusdBalance = await liquity.lusdToken.balanceOf(
            userWallet.address
          );

          expect(
            troveDebt,
            `Trove debt should have increased by at least ${borrowAmount} ETH`
          ).to.gte(expectedTroveDebt);

          expect(
            userLusdBalance,
            `User LUSD balance should equal the borrowed LUSD due to the second withdraw spell`
          ).eq(borrowAmount);
        });

        it("returns Instadapp event name and data", async () => {
          // Create a dummy Trove
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const borrowAmount = ethers.utils.parseUnits("1000", 18); // 1000 LUSD
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee
          const borrowSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "borrow",
            args: [maxFeePercentage, borrowAmount, upperHint, lowerHint, 0, 0],
          };

          const borrowTx = await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([borrowSpell]), userWallet.address);

          const receipt = await borrowTx.wait();
          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256", "uint256"],
            [dsaWallet0.address, borrowAmount, 0, 0]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogBorrow(address,uint256,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("repay()", () => {
        it("repays LUSD to a Trove", async () => {
          const depositAmount = ethers.utils.parseEther("5");
          const borrowAmount = ethers.utils.parseUnits("2500", 18);

          // Create a dummy Trove
          await helpers.createDsaTrove(
            dsaWallet0,
            userWallet,
            liquity,
            depositAmount,
            borrowAmount
          );

          const troveDebtBefore = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          // DSA account is holding 2500 LUSD from opening a Trove, so we use some of that to repay
          const repayAmount = ethers.utils.parseUnits("100", 18); // 100 LUSD

          const { upperHint, lowerHint } = await helpers.getTroveInsertionHints(
            depositAmount,
            borrowAmount,
            liquity
          );
          const repaySpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "repay",
            args: [repayAmount, upperHint, lowerHint, 0, 0],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([repaySpell]), userWallet.address);

          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const expectedTroveDebt = troveDebtBefore.sub(repayAmount);

          expect(
            troveDebt,
            `Trove debt should have decreased by ${repayAmount} ETH`
          ).to.eq(expectedTroveDebt);
        });

        it("repays LUSD to a Trove using LUSD collected from a previous spell", async () => {
          const depositAmount = ethers.utils.parseEther("5");
          const borrowAmount = ethers.utils.parseUnits("2500", 18);

          // Create a dummy Trove
          await helpers.createDsaTrove(
            dsaWallet0,
            userWallet,
            liquity,
            depositAmount,
            borrowAmount
          );

          const troveDebtBefore = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );

          const repayAmount = ethers.utils.parseUnits("100", 18); // 100 LUSD
          const { upperHint, lowerHint } = await helpers.getTroveInsertionHints(
            depositAmount,
            borrowAmount,
            liquity
          );

          // Drain the DSA's LUSD balance so that we ensure we are repaying using LUSD from a previous spell
          await helpers.sendToken(
            liquity.lusdToken,
            borrowAmount,
            dsaWallet0.address,
            userWallet.address
          );

          // Allow DSA to spend user's LUSD
          await liquity.lusdToken
            .connect(userWallet)
            .approve(dsaWallet0.address, repayAmount);

          const lusdDepositId = 1;
          const depositSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "deposit",
            args: [liquity.lusdToken.address, repayAmount, 0, lusdDepositId],
          };
          const borrowSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "repay",
            args: [0, upperHint, lowerHint, lusdDepositId, 0],
          };

          const spells = [depositSpell, borrowSpell];

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address);

          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const expectedTroveDebt = troveDebtBefore.sub(repayAmount);

          expect(
            troveDebt,
            `Trove debt should have decreased by ${repayAmount} ETH`
          ).to.eq(expectedTroveDebt);
        });

        it("returns Instadapp event name and data", async () => {
          // Create a dummy Trove
          const depositAmount = ethers.utils.parseEther("5");
          const borrowAmount = ethers.utils.parseUnits("2500", 18);
          await helpers.createDsaTrove(
            dsaWallet0,
            userWallet,
            liquity,
            depositAmount,
            borrowAmount
          );

          const repayAmount = ethers.utils.parseUnits("100", 18); // 100 LUSD
          const { upperHint, lowerHint } = await helpers.getTroveInsertionHints(
            depositAmount,
            borrowAmount,
            liquity
          );

          const borrowSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "repay",
            args: [repayAmount, upperHint, lowerHint, 0, 0],
          };

          const repayTx = await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([borrowSpell]), userWallet.address, {
              value: repayAmount,
            });

          const receipt = await repayTx.wait();
          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256", "uint256"],
            [dsaWallet0.address, repayAmount, 0, 0]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogRepay(address,uint256,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("adjust()", () => {
        it("adjusts a Trove: deposit ETH and borrow LUSD", async () => {
          // Create a dummy Trove
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const troveCollateralBefore = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );
          const troveDebtBefore = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const depositAmount = ethers.utils.parseEther("1"); // 1 ETH
          const borrowAmount = ethers.utils.parseUnits("500", 18); // 500 LUSD
          const withdrawAmount = 0;
          const repayAmount = 0;
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee

          const adjustSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "adjust",
            args: [
              maxFeePercentage,
              depositAmount,
              withdrawAmount,
              borrowAmount,
              repayAmount,
              upperHint,
              lowerHint,
              [0, 0, 0, 0],
              [0, 0, 0, 0],
            ],
          };

          // Adjust Trove by depositing ETH and borrowing LUSD
          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([adjustSpell]), userWallet.address, {
              value: depositAmount,
              gasLimit: helpers.MAX_GAS,
            });

          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const expectedTroveColl = troveCollateralBefore.add(depositAmount);
          const expectedTroveDebt = troveDebtBefore.add(borrowAmount);

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
          // Create a dummy Trove
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const troveCollateralBefore = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );
          const troveDebtBefore = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const depositAmount = 0;
          const borrowAmount = 0;
          const withdrawAmount = ethers.utils.parseEther("1"); // 1 ETH;
          const repayAmount = ethers.utils.parseUnits("10", 18); // 10 LUSD;
          const { upperHint, lowerHint } = await helpers.getTroveInsertionHints(
            troveCollateralBefore.sub(withdrawAmount),
            troveDebtBefore.sub(repayAmount),
            liquity
          );
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee

          const adjustSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "adjust",
            args: [
              maxFeePercentage,
              depositAmount,
              withdrawAmount,
              borrowAmount,
              repayAmount,
              upperHint,
              lowerHint,
              [0, 0, 0, 0],
              [0, 0, 0, 0],
            ],
          };

          // Adjust Trove by withdrawing ETH and repaying LUSD
          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([adjustSpell]), userWallet.address, {
              value: depositAmount,
              gasLimit: helpers.MAX_GAS,
            });

          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const expectedTroveColl = troveCollateralBefore.sub(withdrawAmount);
          const expectedTroveDebt = troveDebtBefore.sub(repayAmount);

          expect(
            troveCollateral,
            `Trove collateral should have increased by ${depositAmount} ETH`
          ).to.eq(expectedTroveColl);

          expect(
            troveDebt,
            `Trove debt should have decreased by at least ${repayAmount} LUSD`
          ).to.gte(expectedTroveDebt);
        });

        it("adjusts a Trove: deposit ETH and repay LUSD using previous spells", async () => {
          // Create a dummy Trove
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const troveCollateralBefore = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );
          const troveDebtBefore = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const depositAmount = ethers.utils.parseEther("1"); // 1 ETH
          const borrowAmount = 0;
          const withdrawAmount = 0;
          const repayAmount = ethers.utils.parseUnits("10", 18); // 10 lUSD
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee

          const ethDepositId = 1;
          const lusdRepayId = 2;

          const depositEthSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "deposit",
            args: [helpers.ETH, depositAmount, 0, ethDepositId],
          };

          const depositLusdSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "deposit",
            args: [liquity.lusdToken.address, repayAmount, 0, lusdRepayId],
          };

          const adjustSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "adjust",
            args: [
              maxFeePercentage,
              0, // Deposit amount comes from a previous spell's storage slot
              withdrawAmount,
              borrowAmount,
              0, // Repay amount comes from a previous spell's storage slot
              upperHint,
              lowerHint,
              [ethDepositId, 0, 0, lusdRepayId],
              [0, 0, 0, 0],
            ],
          };
          const spells = [depositEthSpell, depositLusdSpell, adjustSpell];

          // Send user some LUSD so they can repay
          await helpers.sendToken(
            liquity.lusdToken,
            repayAmount,
            helpers.JUSTIN_SUN_ADDRESS,
            userWallet.address
          );

          // Allow DSA to spend user's LUSD
          await liquity.lusdToken
            .connect(userWallet)
            .approve(dsaWallet0.address, repayAmount);

          // Adjust Trove by depositing ETH and repaying LUSD
          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address, {
              value: depositAmount,
              gasLimit: helpers.MAX_GAS,
            });

          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );
          const troveDebt = await liquity.troveManager.getTroveDebt(
            dsaWallet0.address
          );
          const expectedTroveColl = troveCollateralBefore.add(depositAmount);
          const expectedTroveDebt = troveDebtBefore.sub(repayAmount);

          expect(
            troveCollateral,
            `Trove collateral should have increased by ${depositAmount} ETH`
          ).to.eq(expectedTroveColl);

          expect(
            troveDebt,
            `Trove debt (${troveDebtBefore}) should have decreased by at least ${repayAmount} LUSD`
          ).to.eq(expectedTroveDebt);
        });

        it("adjusts a Trove: withdraw ETH, borrow LUSD, and store the amounts for other spells", async () => {
          // Create a dummy Trove
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const userEthBalanceBefore = await ethers.provider.getBalance(
            userWallet.address
          );
          const userLusdBalanceBefore = await liquity.lusdToken.balanceOf(
            userWallet.address
          );

          const depositAmount = 0;
          const borrowAmount = ethers.utils.parseUnits("100", 18); // 100 LUSD
          const withdrawAmount = ethers.utils.parseEther("1"); // 1 ETH
          const repayAmount = 0;
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee

          const ethWithdrawId = 1;
          const lusdBorrowId = 2;

          const adjustSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "adjust",
            args: [
              maxFeePercentage,
              depositAmount,
              withdrawAmount,
              borrowAmount,
              repayAmount,
              upperHint,
              lowerHint,
              [0, 0, 0, 0],
              [0, ethWithdrawId, lusdBorrowId, 0],
            ],
          };

          const withdrawEthSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "withdraw",
            args: [helpers.ETH, 0, userWallet.address, ethWithdrawId, 0],
          };

          const withdrawLusdSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "withdraw",
            args: [
              liquity.lusdToken.address,
              0,
              userWallet.address,
              lusdBorrowId,
              0,
            ],
          };

          const spells = [adjustSpell, withdrawEthSpell, withdrawLusdSpell];

          // Adjust Trove by withdrawing ETH and borrowing LUSD
          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address, {
              gasLimit: helpers.MAX_GAS,
            });

          const userEthBalanceAfter = await ethers.provider.getBalance(
            userWallet.address
          );
          const userLusdBalanceAfter = await liquity.lusdToken.balanceOf(
            userWallet.address
          );
          expect(userEthBalanceAfter).lt(
            userEthBalanceBefore.add(withdrawAmount)
          );
          expect(userLusdBalanceAfter).eq(
            userLusdBalanceBefore.add(borrowAmount)
          );
        });

        it("returns Instadapp event name and data", async () => {
          // Create a dummy Trove
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          const depositAmount = ethers.utils.parseEther("1"); // 1 ETH
          const borrowAmount = ethers.utils.parseUnits("500", 18); // 500 LUSD
          const withdrawAmount = 0;
          const repayAmount = 0;
          const upperHint = ethers.constants.AddressZero;
          const lowerHint = ethers.constants.AddressZero;
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee

          const adjustSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "adjust",
            args: [
              maxFeePercentage,
              depositAmount,
              withdrawAmount,
              borrowAmount,
              repayAmount,
              upperHint,
              lowerHint,
              [0, 0, 0, 0],
              [0, 0, 0, 0],
            ],
          };

          const adjustTx = await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([adjustSpell]), userWallet.address, {
              value: depositAmount,
              gasLimit: helpers.MAX_GAS,
            });

          const receipt = await adjustTx.wait();
          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            [
              "address",
              "uint256",
              "uint256",
              "uint256",
              "uint256",
              "uint256",
              "uint256[]",
              "uint256[]",
            ],
            [
              dsaWallet0.address,
              maxFeePercentage,
              depositAmount,
              withdrawAmount,
              borrowAmount,
              repayAmount,
              [0, 0, 0, 0],
              [0, 0, 0, 0],
            ]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogAdjust(address,uint256,uint256,uint256,uint256,uint256,uint256[],uint256[])"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("claimCollateralFromRedemption()", () => {
        it("claims collateral from a redeemed Trove", async () => {
          // Create a low collateralized Trove
          const depositAmount = ethers.utils.parseEther("1.5");
          const borrowAmount = ethers.utils.parseUnits("2500", 18);

          await helpers.createDsaTrove(
            dsaWallet0,
            userWallet,
            liquity,
            depositAmount,
            borrowAmount
          );

          // Redeem lots of LUSD to cause the Trove to become redeemed
          const redeemAmount = ethers.utils.parseUnits("10000000", 18);
          await helpers.sendToken(
            liquity.lusdToken,
            redeemAmount,
            contracts.STABILITY_POOL_ADDRESS,
            userWallet.address
          );
          const {
            partialRedemptionHintNicr,
            firstRedemptionHint,
            upperHint,
            lowerHint,
          } = await helpers.getRedemptionHints(redeemAmount, liquity);
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee

          await liquity.troveManager
            .connect(userWallet)
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

          const remainingEthCollateral = await liquity.collSurplus.getCollateral(
            dsaWallet0.address
          );

          // Claim the remaining collateral from the redeemed Trove
          const claimCollateralFromRedemptionSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "claimCollateralFromRedemption",
            args: [0],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(
              ...encodeSpells([claimCollateralFromRedemptionSpell]),
              userWallet.address
            );

          const ethBalance = await ethers.provider.getBalance(
            dsaWallet0.address
          );

          expect(ethBalance).to.eq(remainingEthCollateral);
        });

        it("returns Instadapp event name and data", async () => {
          // Create a low collateralized Trove
          const depositAmount = ethers.utils.parseEther("1.5");
          const borrowAmount = ethers.utils.parseUnits("2500", 18);

          await helpers.createDsaTrove(
            dsaWallet0,
            userWallet,
            liquity,
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
            userWallet.address
          );
          const {
            partialRedemptionHintNicr,
            firstRedemptionHint,
            upperHint,
            lowerHint,
          } = await helpers.getRedemptionHints(redeemAmount, liquity);
          const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee

          await liquity.troveManager
            .connect(userWallet)
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
            dsaWallet0.address
          );

          const claimCollateralFromRedemptionSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "claimCollateralFromRedemption",
            args: [setId],
          };

          const claimTx = await dsaWallet0
            .connect(userWallet)
            .cast(
              ...encodeSpells([claimCollateralFromRedemptionSpell]),
              userWallet.address
            );

          const receipt = await claimTx.wait();
          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256"],
            [dsaWallet0.address, claimAmount, setId]
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
            dsaWallet0.address
          );

          const stabilityDepositSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stabilityDeposit",
            args: [amount, frontendTag, 0, 0, 0, 0],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([stabilityDepositSpell]), userWallet.address);

          const depositedAmount = await liquity.stabilityPool.getCompoundedLUSDDeposit(
            dsaWallet0.address
          );
          expect(depositedAmount).to.eq(amount);
        });

        it("deposits into Stability Pool using LUSD collected from a previous spell", async () => {
          const amount = ethers.utils.parseUnits("100", 18);
          const frontendTag = ethers.constants.AddressZero;

          await helpers.sendToken(
            liquity.lusdToken,
            amount,
            contracts.STABILITY_POOL_ADDRESS,
            userWallet.address
          );
          const lusdDepositId = 1;

          const depositLusdSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "deposit",
            args: [liquity.lusdToken.address, amount, 0, lusdDepositId],
          };
          const stabilityDepositSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stabilityDeposit",
            args: [0, frontendTag, lusdDepositId, 0, 0, 0],
          };
          const spells = [depositLusdSpell, stabilityDepositSpell];

          // Allow DSA to spend user's LUSD
          await liquity.lusdToken
            .connect(userWallet)
            .approve(dsaWallet0.address, amount);

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address);

          const depositedAmount = await liquity.stabilityPool.getCompoundedLUSDDeposit(
            dsaWallet0.address
          );
          expect(depositedAmount).to.eq(amount);
        });

        it("returns Instadapp event name and data", async () => {
          const amount = ethers.utils.parseUnits("100", 18);
          const halfAmount = amount.div(2);
          const frontendTag = ethers.constants.AddressZero;
          const getDepositId = 0;
          const setDepositId = 0;
          const setEthGainId = 0;
          const setLqtyGainId = 0;

          await helpers.sendToken(
            liquity.lusdToken,
            amount,
            contracts.STABILITY_POOL_ADDRESS,
            dsaWallet0.address
          );

          const stabilityDepositSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stabilityDeposit",
            args: [
              halfAmount,
              frontendTag,
              getDepositId,
              setDepositId,
              setEthGainId,
              setLqtyGainId,
            ],
          };

          // Create a Stability deposit for this DSA
          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([stabilityDepositSpell]), userWallet.address);

          // Liquidate a Trove to cause an ETH gain
          await liquity.troveManager.connect(userWallet).liquidateTroves(1, {
            gasLimit: helpers.MAX_GAS,
          });

          // Fast forward in time so we have an LQTY gain
          await provider.send("evm_increaseTime", [600]);
          await provider.send("evm_mine", []);

          // Create a Stability Pool deposit with a differen DSA so that LQTY gains can be calculated
          // See: https://github.com/liquity/dev/#lqty-reward-events-and-payouts
          const tempDsa = await buildDSAv2(userWallet.address);
          await helpers.sendToken(
            liquity.lusdToken,
            amount,
            contracts.STABILITY_POOL_ADDRESS,
            tempDsa.address
          );
          await tempDsa
            .connect(userWallet)
            .cast(...encodeSpells([stabilityDepositSpell]), userWallet.address);

          const ethGain = await liquity.stabilityPool.getDepositorETHGain(
            dsaWallet0.address
          );
          const lqtyGain = await liquity.stabilityPool.getDepositorLQTYGain(
            dsaWallet0.address
          );

          // Top up the user's deposit so that we can track their ETH and LQTY gain
          const depositAgainTx = await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([stabilityDepositSpell]), userWallet.address);

          const receipt = await depositAgainTx.wait();
          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            [
              "address",
              "uint256",
              "uint256",
              "uint256",
              "address",
              "uint256",
              "uint256",
              "uint256",
              "uint256",
            ],
            [
              dsaWallet0.address,
              halfAmount,
              ethGain,
              lqtyGain,
              frontendTag,
              getDepositId,
              setDepositId,
              setEthGainId,
              setLqtyGainId,
            ]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogStabilityDeposit(address,uint256,uint256,uint256,address,uint256,uint256,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("stabilityWithdraw()", () => {
        it("withdraws from Stability Pool", async () => {
          // Start this test from scratch since we need to remove any liquidatable Troves withdrawing from Stability Pool
          [liquity, dsaWallet0] = await helpers.resetInitialState(
            userWallet.address,
            contracts
          );

          // The current block number has liquidatable Troves.
          // Remove them otherwise Stability Pool withdrawals are disabled
          await liquity.troveManager.connect(userWallet).liquidateTroves(90, {
            gasLimit: helpers.MAX_GAS,
          });

          const amount = ethers.utils.parseUnits("100", 18);
          const frontendTag = ethers.constants.AddressZero;

          await helpers.sendToken(
            liquity.lusdToken,
            amount,
            contracts.STABILITY_POOL_ADDRESS,
            dsaWallet0.address
          );

          const stabilityDepositSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stabilityDeposit",
            args: [amount, frontendTag, 0, 0, 0, 0],
          };

          // Withdraw half of the deposit
          const stabilityWithdrawSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stabilityWithdraw",
            args: [amount.div(2), 0, 0, 0, 0],
          };
          const spells = [stabilityDepositSpell, stabilityWithdrawSpell];

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address);

          const depositedAmount = await liquity.stabilityPool.getCompoundedLUSDDeposit(
            dsaWallet0.address
          );
          const dsaLusdBalance = await liquity.lusdToken.balanceOf(
            dsaWallet0.address
          );

          expect(depositedAmount).to.eq(amount.div(2));
          expect(dsaLusdBalance).to.eq(amount.div(2));
        });

        it("withdraws from Stability Pool and stores the LUSD for other spells", async () => {
          // Start this test from scratch since we need to remove any liquidatable Troves withdrawing from Stability Pool
          [liquity, dsaWallet0] = await helpers.resetInitialState(
            userWallet.address,
            contracts
          );

          // The current block number has liquidatable Troves.
          // Remove them otherwise Stability Pool withdrawals are disabled
          await liquity.troveManager.connect(userWallet).liquidateTroves(90, {
            gasLimit: helpers.MAX_GAS,
          });
          const amount = ethers.utils.parseUnits("100", 18);
          const frontendTag = ethers.constants.AddressZero;
          const withdrawId = 1;

          await helpers.sendToken(
            liquity.lusdToken,
            amount,
            contracts.STABILITY_POOL_ADDRESS,
            dsaWallet0.address
          );

          const stabilityDepositSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stabilityDeposit",
            args: [amount, frontendTag, 0, 0, 0, 0],
          };

          // Withdraw half of the deposit
          const stabilityWithdrawSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stabilityWithdraw",
            args: [amount.div(2), 0, 0, 0, withdrawId],
          };

          const withdrawLusdSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "withdraw",
            args: [
              liquity.lusdToken.address,
              0,
              userWallet.address,
              withdrawId,
              0,
            ],
          };

          const spells = [
            stabilityDepositSpell,
            stabilityWithdrawSpell,
            withdrawLusdSpell,
          ];

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address);

          const depositedAmount = await liquity.stabilityPool.getCompoundedLUSDDeposit(
            dsaWallet0.address
          );
          const walletLusdBalance = await liquity.lusdToken.balanceOf(
            dsaWallet0.address
          );

          expect(depositedAmount).to.eq(amount.div(2));
          expect(walletLusdBalance).to.eq(amount.div(2));
        });

        it("returns Instadapp event name and data", async () => {
          // Start this test from scratch since we need to remove any liquidatable Troves withdrawing from Stability Pool
          [liquity, dsaWallet0] = await helpers.resetInitialState(
            userWallet.address,
            contracts
          );

          const amount = ethers.utils.parseUnits("100", 18);
          const frontendTag = ethers.constants.AddressZero;

          await helpers.sendToken(
            liquity.lusdToken,
            amount,
            contracts.STABILITY_POOL_ADDRESS,
            dsaWallet0.address
          );

          const stabilityDepositSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stabilityDeposit",
            args: [amount, frontendTag, 0, 0, 0, 0],
          };

          // Withdraw half of the deposit
          const withdrawAmount = amount.div(2);
          const getWithdrawId = 0;
          const setWithdrawId = 0;
          const setEthGainId = 0;
          const setLqtyGainId = 0;

          // Create a Stability Pool deposit
          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([stabilityDepositSpell]), userWallet.address);

          // The current block number has liquidatable Troves.
          // Remove them otherwise Stability Pool withdrawals are disabled
          await liquity.troveManager.connect(userWallet).liquidateTroves(90, {
            gasLimit: helpers.MAX_GAS,
          });

          // Fast forward in time so we have an LQTY gain
          await provider.send("evm_increaseTime", [600]);
          await provider.send("evm_mine", []);

          // Create another Stability Pool deposit so that LQTY gains are realized
          // See: https://github.com/liquity/dev/#lqty-reward-events-and-payouts
          const tempDsa = await buildDSAv2(userWallet.address);
          await helpers.sendToken(
            liquity.lusdToken,
            amount,
            contracts.STABILITY_POOL_ADDRESS,
            tempDsa.address
          );
          await tempDsa
            .connect(userWallet)
            .cast(...encodeSpells([stabilityDepositSpell]), userWallet.address);

          const ethGain = await liquity.stabilityPool.getDepositorETHGain(
            dsaWallet0.address
          );
          const lqtyGain = await liquity.stabilityPool.getDepositorLQTYGain(
            dsaWallet0.address
          );

          const stabilityWithdrawSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stabilityWithdraw",
            args: [
              withdrawAmount,
              getWithdrawId,
              setWithdrawId,
              setEthGainId,
              setLqtyGainId,
            ],
          };

          const withdrawTx = await dsaWallet0
            .connect(userWallet)
            .cast(
              ...encodeSpells([stabilityWithdrawSpell]),
              userWallet.address
            );

          const receipt = await withdrawTx.wait();
          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
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
            ],
            [
              dsaWallet0.address,
              withdrawAmount,
              ethGain,
              lqtyGain,
              getWithdrawId,
              setWithdrawId,
              setEthGainId,
              setLqtyGainId,
            ]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogStabilityWithdraw(address,uint256,uint256,uint256,uint256,uint256,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("stabilityMoveEthGainToTrove()", () => {
        beforeEach(async () => {
          // Start these test from fresh so that we definitely have a liquidatable Trove within this block
          [liquity, dsaWallet0] = await helpers.resetInitialState(
            userWallet.address,
            contracts
          );
        });

        it("moves ETH gain from Stability Pool to Trove", async () => {
          // Create a DSA owned Trove to capture ETH liquidation gains
          // Create a dummy Trove
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);
          const troveCollateralBefore = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );

          // Create a Stability Deposit using the Trove's borrowed LUSD
          const amount = ethers.utils.parseUnits("100", 18);
          const frontendTag = ethers.constants.AddressZero;
          const stabilityDepositSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stabilityDeposit",
            args: [amount, frontendTag, 0, 0, 0, 0],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([stabilityDepositSpell]), userWallet.address);

          // Liquidate a Trove to create an ETH gain for the new DSA Trove
          await liquity.troveManager
            .connect(userWallet)
            .liquidate(helpers.LIQUIDATABLE_TROVE_ADDRESS, {
              gasLimit: helpers.MAX_GAS, // permit max gas
            });

          const ethGainFromLiquidation = await liquity.stabilityPool.getDepositorETHGain(
            dsaWallet0.address
          );

          // Move ETH gain to Trove
          const moveEthGainSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stabilityMoveEthGainToTrove",
            args: [ethers.constants.AddressZero, ethers.constants.AddressZero],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([moveEthGainSpell]), userWallet.address);

          const ethGainAfterMove = await liquity.stabilityPool.getDepositorETHGain(
            dsaWallet0.address
          );
          const troveCollateral = await liquity.troveManager.getTroveColl(
            dsaWallet0.address
          );
          const expectedTroveCollateral = troveCollateralBefore.add(
            ethGainFromLiquidation
          );
          expect(ethGainAfterMove).to.eq(0);
          expect(troveCollateral).to.eq(expectedTroveCollateral);
        });

        it("returns Instadapp event name and data", async () => {
          // Create a DSA owned Trove to capture ETH liquidation gains
          // Create a dummy Trove
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          // Create a Stability Deposit using the Trove's borrowed LUSD
          const amount = ethers.utils.parseUnits("100", 18);
          const frontendTag = ethers.constants.AddressZero;
          const stabilityDepositSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stabilityDeposit",
            args: [amount, frontendTag, 0, 0, 0, 0],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([stabilityDepositSpell]), userWallet.address);

          // Liquidate a Trove to create an ETH gain for the new DSA Trove
          await liquity.troveManager
            .connect(userWallet)
            .liquidate(helpers.LIQUIDATABLE_TROVE_ADDRESS, {
              gasLimit: helpers.MAX_GAS, // permit max gas
            });

          const ethGainFromLiquidation = await liquity.stabilityPool.getDepositorETHGain(
            dsaWallet0.address
          );

          // Move ETH gain to Trove
          const moveEthGainSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stabilityMoveEthGainToTrove",
            args: [ethers.constants.AddressZero, ethers.constants.AddressZero],
          };

          const moveEthGainTx = await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([moveEthGainSpell]), userWallet.address);

          const receipt = await moveEthGainTx.wait();

          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256"],
            [dsaWallet0.address, ethGainFromLiquidation]
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
            dsaWallet0.address
          );

          const stakeSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stake",
            args: [amount, 0, 0, 0, 0],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([stakeSpell]), userWallet.address);

          const lqtyBalance = await liquity.lqtyToken.balanceOf(
            dsaWallet0.address
          );
          expect(lqtyBalance).to.eq(0);

          const totalStakingBalance = await liquity.lqtyToken.balanceOf(
            contracts.STAKING_ADDRESS
          );
          expect(totalStakingBalance).to.eq(
            totalStakingBalanceBefore.add(amount)
          );
        });

        it("stakes LQTY using LQTY obtained from a previous spell", async () => {
          const totalStakingBalanceBefore = await liquity.lqtyToken.balanceOf(
            contracts.STAKING_ADDRESS
          );

          const amount = ethers.utils.parseUnits("1", 18);
          await helpers.sendToken(
            liquity.lqtyToken,
            amount,
            helpers.JUSTIN_SUN_ADDRESS,
            userWallet.address
          );

          const lqtyDepositId = 1;
          const depositSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "deposit",
            args: [liquity.lqtyToken.address, amount, 0, lqtyDepositId],
          };
          const stakeSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stake",
            args: [0, lqtyDepositId, 0, 0, 0],
          };
          const spells = [depositSpell, stakeSpell];

          // Allow DSA to spend user's LQTY
          await liquity.lqtyToken
            .connect(userWallet)
            .approve(dsaWallet0.address, amount);

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address);

          const lqtyBalance = await liquity.lqtyToken.balanceOf(
            dsaWallet0.address
          );
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
            dsaWallet0.address
          );

          const getStakeId = 0;
          const setStakeId = 0;
          const setEthGainId = 0;
          const setLusdGainId = 0;
          const stakeSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stake",
            args: [amount, getStakeId, setStakeId, setEthGainId, setLusdGainId],
          };

          const stakeTx = await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([stakeSpell]), userWallet.address);

          const receipt = await stakeTx.wait();

          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256", "uint256", "uint256", "uint256"],
            [
              dsaWallet0.address,
              amount,
              getStakeId,
              setStakeId,
              setEthGainId,
              setLusdGainId,
            ]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogStake(address,uint256,uint256,uint256,uint256,uint256)"
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
            dsaWallet0.address
          );

          const stakeSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stake",
            args: [amount, 0, 0, 0, 0],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([stakeSpell]), userWallet.address);

          const totalStakingBalanceBefore = await liquity.lqtyToken.balanceOf(
            contracts.STAKING_ADDRESS
          );
          const unstakeSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "unstake",
            args: [amount, 0, 0, 0, 0],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([unstakeSpell]), userWallet.address);

          const lqtyBalance = await liquity.lqtyToken.balanceOf(
            dsaWallet0.address
          );
          expect(lqtyBalance).to.eq(amount);

          const totalStakingBalance = await liquity.lqtyToken.balanceOf(
            contracts.STAKING_ADDRESS
          );
          expect(totalStakingBalance).to.eq(
            totalStakingBalanceBefore.sub(amount)
          );
        });

        it("unstakes LQTY and stores the LQTY for other spells", async () => {
          const amount = ethers.utils.parseUnits("1", 18);
          await helpers.sendToken(
            liquity.lqtyToken,
            amount,
            helpers.JUSTIN_SUN_ADDRESS,
            dsaWallet0.address
          );

          const stakeSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stake",
            args: [amount, 0, 0, 0, 0],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([stakeSpell]), userWallet.address);

          const totalStakingBalanceBefore = await liquity.lqtyToken.balanceOf(
            contracts.STAKING_ADDRESS
          );
          const withdrawId = 1;
          const unstakeSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "unstake",
            args: [amount, 0, withdrawId, 0, 0],
          };

          const withdrawLqtySpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "withdraw",
            args: [
              liquity.lqtyToken.address,
              0,
              userWallet.address,
              withdrawId,
              0,
            ],
          };
          const spells = [unstakeSpell, withdrawLqtySpell];
          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address);

          const lqtyBalance = await liquity.lqtyToken.balanceOf(
            dsaWallet0.address
          );
          const totalStakingBalance = await liquity.lqtyToken.balanceOf(
            contracts.STAKING_ADDRESS
          );
          const userLqtyBalance = await liquity.lqtyToken.balanceOf(
            userWallet.address
          );
          expect(lqtyBalance).to.eq(0);
          expect(totalStakingBalance).to.eq(
            totalStakingBalanceBefore.sub(amount)
          );
          expect(userLqtyBalance).to.eq(amount);
        });

        it("returns Instadapp event name and data", async () => {
          const amount = ethers.utils.parseUnits("1", 18);
          await helpers.sendToken(
            liquity.lqtyToken,
            amount,
            helpers.JUSTIN_SUN_ADDRESS,
            dsaWallet0.address
          );

          const stakeSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stake",
            args: [amount, 0, 0, 0, 0],
          };

          await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([stakeSpell]), userWallet.address);

          const getUnstakeId = 0;
          const setUnstakeId = 0;
          const setEthGainId = 0;
          const setLusdGainId = 0;
          const unstakeSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "unstake",
            args: [
              amount,
              getUnstakeId,
              setUnstakeId,
              setEthGainId,
              setLusdGainId,
            ],
          };

          const unstakeTx = await dsaWallet0
            .connect(userWallet)
            .cast(...encodeSpells([unstakeSpell]), userWallet.address);

          const receipt = await unstakeTx.wait();

          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256", "uint256", "uint256", "uint256"],
            [
              dsaWallet0.address,
              amount,
              getUnstakeId,
              setUnstakeId,
              setEthGainId,
              setLusdGainId,
            ]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogUnstake(address,uint256,uint256,uint256,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });

      describe("claimStakingGains()", () => {
        it("claims gains from staking", async () => {
          const stakerDsa = await buildDSAv2(userWallet.address);
          const amount = ethers.utils.parseUnits("1000", 18); // 1000 LQTY

          // Stake lots of LQTY
          await helpers.sendToken(
            liquity.lqtyToken,
            amount,
            helpers.JUSTIN_SUN_ADDRESS,
            stakerDsa.address
          );
          const stakeSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stake",
            args: [amount, 0, 0, 0, 0],
          };
          await stakerDsa
            .connect(userWallet)
            .cast(...encodeSpells([stakeSpell]), userWallet.address);

          // Open a Trove to cause an ETH issuance gain for stakers
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          // Redeem some ETH to cause an LUSD redemption gain for stakers
          await helpers.redeem(
            ethers.utils.parseUnits("1000", 18),
            contracts.STABILITY_POOL_ADDRESS,
            userWallet,
            liquity
          );

          const setEthGainId = 0;
          const setLusdGainId = 0;
          const ethGain = await liquity.staking.getPendingETHGain(
            stakerDsa.address
          );
          const lusdGain = await liquity.staking.getPendingLUSDGain(
            stakerDsa.address
          );

          const claimStakingGainsSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "claimStakingGains",
            args: [setEthGainId, setLusdGainId],
          };

          const ethBalanceBefore = await ethers.provider.getBalance(
            stakerDsa.address
          );

          // Claim gains
          await stakerDsa
            .connect(userWallet)
            .cast(
              ...encodeSpells([claimStakingGainsSpell]),
              userWallet.address
            );

          const ethBalanceAfter = await ethers.provider.getBalance(
            stakerDsa.address
          );
          const lusdBalanceAfter = await liquity.lusdToken.balanceOf(
            stakerDsa.address
          );
          expect(ethBalanceAfter).to.eq(ethBalanceBefore.add(ethGain));
          expect(lusdBalanceAfter).to.eq(lusdGain);
        });

        it("claims gains from staking and stores them for other spells", async () => {
          const stakerDsa = await buildDSAv2(userWallet.address);
          const amount = ethers.utils.parseUnits("1000", 18); // 1000 LQTY

          // Stake lots of LQTY
          await helpers.sendToken(
            liquity.lqtyToken,
            amount,
            helpers.JUSTIN_SUN_ADDRESS,
            stakerDsa.address
          );
          const stakeSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stake",
            args: [amount, 0, 0, 0, 0],
          };
          await stakerDsa
            .connect(userWallet)
            .cast(...encodeSpells([stakeSpell]), userWallet.address);

          // Open a Trove to cause an ETH issuance gain for stakers
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          // Redeem some ETH to cause an LUSD redemption gain for stakers
          await helpers.redeem(
            ethers.utils.parseUnits("1000", 18),
            contracts.STABILITY_POOL_ADDRESS,
            userWallet,
            liquity
          );

          const ethGain = await liquity.staking.getPendingETHGain(
            stakerDsa.address
          );
          const lusdGain = await liquity.staking.getPendingLUSDGain(
            stakerDsa.address
          );
          const lusdBalanceBefore = await liquity.lusdToken.balanceOf(
            userWallet.address
          );
          const ethBalanceBefore = await ethers.provider.getBalance(
            userWallet.address
          );
          const ethGainId = 111;
          const lusdGainId = 222;

          const claimStakingGainsSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "claimStakingGains",
            args: [ethGainId, lusdGainId],
          };

          const withdrawEthSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "withdraw",
            args: [helpers.ETH, 0, userWallet.address, ethGainId, 0],
          };

          const withdrawLusdSpell = {
            connector: helpers.INSTADAPP_BASIC_V1_CONNECTOR,
            method: "withdraw",
            args: [
              liquity.lusdToken.address,
              0,
              userWallet.address,
              lusdGainId,
              0,
            ],
          };

          const spells = [
            claimStakingGainsSpell,
            withdrawEthSpell,
            withdrawLusdSpell,
          ];

          // Claim gains
          await stakerDsa
            .connect(userWallet)
            .cast(...encodeSpells(spells), userWallet.address, {
              ce: 0,
            });

          const ethBalanceAfter = await ethers.provider.getBalance(
            userWallet.address
          );
          const lusdBalanceAfter = await liquity.lusdToken.balanceOf(
            userWallet.address
          );

          expect(
            ethBalanceAfter,
            "User's ETH balance should have increased by the issuance gain from staking"
          ).to.eq(ethBalanceBefore.add(ethGain));
          expect(
            lusdBalanceAfter,
            "User's LUSD balance should have increased by the redemption gain from staking"
          ).to.eq(lusdBalanceBefore.add(lusdGain));
        });

        it("returns Instadapp event name and data", async () => {
          const stakerDsa = await buildDSAv2(userWallet.address);
          const amount = ethers.utils.parseUnits("1000", 18); // 1000 LQTY

          // Stake lots of LQTY
          await helpers.sendToken(
            liquity.lqtyToken,
            amount,
            helpers.JUSTIN_SUN_ADDRESS,
            stakerDsa.address
          );
          const stakeSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "stake",
            args: [amount, 0, 0, 0, 0],
          };
          await stakerDsa
            .connect(userWallet)
            .cast(...encodeSpells([stakeSpell]), userWallet.address);

          // Open a Trove to cause an ETH issuance gain for stakers
          await helpers.createDsaTrove(dsaWallet0, userWallet, liquity);

          // Redeem some ETH to cause an LUSD redemption gain for stakers
          await helpers.redeem(
            ethers.utils.parseUnits("1000", 18),
            contracts.STABILITY_POOL_ADDRESS,
            userWallet,
            liquity
          );

          const setEthGainId = 0;
          const setLusdGainId = 0;
          const ethGain = await liquity.staking.getPendingETHGain(
            stakerDsa.address
          );
          const lusdGain = await liquity.staking.getPendingLUSDGain(
            stakerDsa.address
          );

          const claimStakingGainsSpell = {
            connector: helpers.LIQUITY_CONNECTOR,
            method: "claimStakingGains",
            args: [setEthGainId, setLusdGainId],
          };

          // Claim gains
          const claimGainsTx = await stakerDsa
            .connect(userWallet)
            .cast(
              ...encodeSpells([claimStakingGainsSpell]),
              userWallet.address
            );

          const receipt = await claimGainsTx.wait();

          const castLogEvent = receipt.events.find(
            (e: { event: string }) => e.event === "LogCast"
          ).args;
          const expectedEventParams = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256", "uint256", "uint256", "uint256"],
            [stakerDsa.address, ethGain, lusdGain, setEthGainId, setLusdGainId]
          );
          expect(castLogEvent.eventNames[0]).eq(
            "LogClaimStakingGains(address,uint256,uint256,uint256,uint256)"
          );
          expect(castLogEvent.eventParams[0]).eq(expectedEventParams);
        });
      });
    });
  });
});
