import { expect } from "chai";
import hre from "hardhat";

const { waffle, ethers } = hre;
const { provider } = waffle;

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/avalanche/addresses";
import { abis } from "../../../scripts/constant/abis";
import { Signer, Contract, BigNumber } from "ethers";

import { ConnectV2PngAvalanche__factory, ConnectV2PngStakeAvalanche__factory } from "../../../typechain";

const PNG_ADDRESS  = "0x60781C2586D68229fde47564546784ab3fACA982";
const WAVAX_ADDRESS = "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7";
const PNG_AVAX_LP_ADDRESS = "0xd7538cABBf8605BdE1f4901B47B8D42c61DE0367";
const PNG_STAKING_ADDRESS = "0x88afdaE1a9F58Da3E68584421937E5F564A0135b";

describe("Pangolin Stake - Avalanche", function () {
    const pangolinConnectorName = "PANGOLIN-TEST-A"
    const pangolinStakeConnectorName = "PANGOLIN-STAKE-TEST-A"
    
    let dsaWallet0: Contract;
    let masterSigner: Signer;
    let instaConnectorsV2: Contract;
    let pangolinConnector: Contract;
    let pangolinStakeConnector: Contract;
    
    let PNG: Contract;

    const wallets = provider.getWallets()
    const [wallet0, wallet1] = wallets
    before(async () => {
        await hre.network.provider.request({
            method: "hardhat_reset",
            params: [
                {
                    forking: {
                        jsonRpcUrl: `https://api.avax.network/ext/bc/C/rpc`,
                        blockNumber: 8197390
                    },
                },
            ],
        });

        PNG = await ethers.getContractAt(
            abis.basic.erc20, 
            PNG_ADDRESS
        );

        masterSigner = await getMasterSigner();
        instaConnectorsV2 = await ethers.getContractAt(
            abis.core.connectorsV2,
            addresses.core.connectorsV2
        );

        // Deploy and enable Pangolin Connector
        pangolinConnector = await deployAndEnableConnector({
            connectorName: pangolinConnectorName,
            contractArtifact: ConnectV2PngAvalanche__factory,
            signer: masterSigner,
            connectors: instaConnectorsV2
        });
        console.log("Pangolin Connector address: "+ pangolinConnector.address);

        // Deploy and enable Pangolin Stake Connector
        pangolinStakeConnector = await deployAndEnableConnector({
            connectorName: pangolinStakeConnectorName,
            contractArtifact: ConnectV2PngStakeAvalanche__factory,
            signer: masterSigner,
            connectors: instaConnectorsV2
        });
        console.log("Pangolin Stake Connector address: "+ pangolinStakeConnector.address);
    })

    it("Should have contracts deployed.", async function () {
        expect(!!instaConnectorsV2.address).to.be.true;
        expect(!!pangolinConnector.address).to.be.true;
        expect(!!pangolinStakeConnector.address).to.be.true;
        expect(!!(await masterSigner.getAddress())).to.be.true;
      });
    
    describe("DSA wallet setup", function () {
        it("Should build DSA v2", async function () {
            dsaWallet0 = await buildDSAv2(wallet0.getAddress())
            expect(!!dsaWallet0.address).to.be.true;
        });

        it("Deposit 10 AVAX into DSA wallet", async function () {
            await wallet0.sendTransaction({
                to: dsaWallet0.address,
                value: ethers.utils.parseEther("10")
            });
            expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
        });
    });

    describe("Pangolin Staking - LP Stake Test", function () {
        let lpAmount: BigNumber;
        let pangolinLPToken: Contract;
        // Buy 100 PNG and deposity in PNG/AVAX LP
        before(async () => {
            const amount = ethers.utils.parseEther("100"); // 100 PNG
            const int_slippage = 0.03
            const slippage = ethers.utils.parseEther(int_slippage.toString());
            const setId = "0";
    
            const PangolinRouterABI = [
                "function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts)"
            ];
    
            // Get amount of AVAX for 200 PNG from Pangolin
            const PangolinRouter = await ethers.getContractAt(
                PangolinRouterABI, 
                "0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106"
            );
            const amounts = await PangolinRouter.getAmountsOut(
                amount, 
                [
                    PNG_ADDRESS, 
                    WAVAX_ADDRESS
                ]
            );

            const amtA = amounts[0];
            const amtB = amounts[1];
            const unitAmt = (amtB * (1 + int_slippage)) / amtA;
            const unitAmount = ethers.utils.parseEther(unitAmt.toString());

            const spells = [
                {
                    connector: pangolinConnectorName,
                    method: "buy",
                    args: [
                        PNG_ADDRESS, 
                        "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", 
                        amount, 
                        unitAmount, 
                        0, 
                        0
                    ]
                },
                {
                    connector: pangolinConnectorName,
                    method: "deposit",
                    args: [
                        PNG_ADDRESS, 
                        "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", 
                        amount, 
                        unitAmount, 
                        slippage, 
                        0, 
                        setId
                    ]
                },
            ];
            // Run spell transaction
            const tx = await dsaWallet0.connect(wallet0).cast(
                ...encodeSpells(spells), wallet1.address
            );
            const receipt = await tx.wait();
            pangolinLPToken = await ethers.getContractAt(
                abis.basic.erc20, 
                PNG_AVAX_LP_ADDRESS
            );
        });

        it("Check if has PNG/AVAX LP", async function () {
            const pangolinPoolAVAXBalance = await pangolinLPToken.balanceOf(dsaWallet0.address);
            expect(pangolinPoolAVAXBalance, `Pangolin PNG/AVAX LP greater than 0`).to.be.gt(0);
            console.log("PNG/AVAX LP: ", ethers.utils.formatUnits(pangolinPoolAVAXBalance, "ether").toString())
            lpAmount = pangolinPoolAVAXBalance;
        });
        
        it("Check if all functions reverts by: Invalid pid!", async function () {
            const pid = BigNumber.from("999999999999");
            const amount = ethers.utils.parseEther("1");
            const getId = 0;
            const setId = 0;

            let spells = [
                {
                    connector: pangolinStakeConnectorName,
                    method: "depositLpStake",
                    args: [
                        pid, 
                        amount, 
                        getId, 
                        setId
                    ]
                }
            ];
            await expect(
                dsaWallet0.connect(wallet0).cast(
                  ...encodeSpells(spells),
                  wallet1.address
                )
            ).to.be.revertedWith("Invalid pid!");

            spells[0].method = "withdrawLpStake"
            await expect(
                dsaWallet0.connect(wallet0).cast(
                  ...encodeSpells(spells),
                  wallet1.address
                )
            ).to.be.revertedWith("Invalid pid!");

            spells[0].method = "withdrawAndClaimLpRewards"
            await expect(
                dsaWallet0.connect(wallet0).cast(
                  ...encodeSpells(spells),
                  wallet1.address
                )
            ).to.be.revertedWith("Invalid pid!");

            spells = [
                {
                    connector: pangolinStakeConnectorName,
                    method: "claimLpRewards",
                    args: [
                        pid
                    ]
                }
            ];
            await expect(
                dsaWallet0.connect(wallet0).cast(
                  ...encodeSpells(spells),
                  wallet1.address
                )
            ).to.be.revertedWith("Invalid pid!");

            spells[0].method = "emergencyWithdrawLpStake"
            await expect(
                dsaWallet0.connect(wallet0).cast(
                  ...encodeSpells(spells),
                  wallet1.address
                )
            ).to.be.revertedWith("Invalid pid!");
        });

        it("Check if all functions reverts by: 'Invalid amount, amount cannot be 0'", async function () {
            let spells = [
                {
                    connector: pangolinStakeConnectorName,
                    method: "depositLpStake",
                    args: [
                        0,
                        0,
                        0,
                        0
                    ]
                }
            ];
            await expect(
                dsaWallet0.connect(wallet0).cast(
                  ...encodeSpells(spells),
                  wallet1.address
                )
            ).to.be.revertedWith("Invalid amount, amount cannot be 0");

            spells[0].method = "withdrawLpStake"
            await expect(
                dsaWallet0.connect(wallet0).cast(
                  ...encodeSpells(spells),
                  wallet1.address
                )
            ).to.be.revertedWith("Invalid amount, amount cannot be 0");

            spells[0].method = "withdrawLpStake"
            await expect(
                dsaWallet0.connect(wallet0).cast(
                  ...encodeSpells(spells),
                  wallet1.address
                )
            ).to.be.revertedWith("Invalid amount, amount cannot be 0");

            spells[0].method = "withdrawAndClaimLpRewards"
            await expect(
                dsaWallet0.connect(wallet0).cast(
                  ...encodeSpells(spells),
                  wallet1.address
                )
            ).to.be.revertedWith("Invalid amount, amount cannot be 0");
        });

        describe("depositLpStake function", function () {
            it("Check if depositLpStake function reverts by: Invalid amount, amount greater than balance of LP token", async function () {
                const amount = lpAmount.mul(2);
                const spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "depositLpStake",
                        args: [
                            0,
                            amount,
                            0,
                            0
                        ]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.revertedWith("Invalid amount, amount greater than balance of LP token");
            });

            it("Check if success in depositLpStake", async function () {
                const spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "depositLpStake",
                        args: [
                            0,
                            lpAmount,
                            0,
                            0
                        ]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.not.reverted;
                // Check if PNG/AVAX LP is equal 0
                const balance = await pangolinLPToken.balanceOf(dsaWallet0.address);
                expect(balance).to.be.eq(0);
            });

            it("Check if depositLpStake function reverts by: Invalid LP token balance", async function () {
                const spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "depositLpStake",
                        args: [
                            0,
                            lpAmount,
                            0,
                            0
                        ]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.revertedWith("Invalid LP token balance");
            });
        });

        describe("claimLpRewards function", function () {
            it("Check if success in claimLpRewards", async function () {
                // Increase Time in 20 seconds
                await hre.network.provider.send("evm_increaseTime", [20]);
                // Mine new block
                await hre.network.provider.send("evm_mine");
                const spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "claimLpRewards",
                        args: [0]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.not.reverted;
                // Checks if the wallet has more than 100 PNG
                const balance = await PNG.balanceOf(dsaWallet0.address);
                expect(balance).to.be.gt(0);
            });
        });

        describe("withdrawLpStake function", function () {
            it("Check if withdrawLpStake function reverts by: Invalid amount, amount greater than balance of staking", async function () {
                const amount = lpAmount.mul(2);
                const spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "withdrawLpStake",
                        args: [
                            0,
                            amount,
                            0,
                            0
                        ]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.revertedWith("Invalid amount, amount greater than balance of staking");
            });

            it("Check if success in withdrawLpStake", async function () {
                const spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "withdrawLpStake",
                        args: [
                            0,
                            lpAmount.div(2),
                            0,
                            0
                        ]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.not.reverted;
                // Check if PNG/AVAX LP is equal 0
                const balance = await pangolinLPToken.balanceOf(dsaWallet0.address);
                expect(balance).to.be.eq(lpAmount.div(2));
            });
        });

        describe("withdrawAndClaimLpRewards function", function () {
            it("Check if withdrawAndClaimLpRewards function reverts by: Invalid amount, amount greater than balance of staking", async function () {
                const amount = lpAmount.mul(2);
                const spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "withdrawAndClaimLpRewards",
                        args: [
                            0,
                            amount,
                            0,
                            0
                        ]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.revertedWith("Invalid amount, amount greater than balance of staking");
            });

            it("Check if success in withdrawAndClaimLpRewards", async function () {
                let balance = await pangolinLPToken.balanceOf(dsaWallet0.address);
                const png_balance = await PNG.balanceOf(dsaWallet0.address);
                const amount = lpAmount.sub(balance)
                const spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "withdrawAndClaimLpRewards",
                        args: [
                            0,
                            amount,
                            0,
                            0
                        ]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.not.reverted;
                // Check if PNG/AVAX LP is equal 0
                balance = await pangolinLPToken.balanceOf(dsaWallet0.address);
                expect(balance).to.be.eq(lpAmount);
                const new_png_balance = await PNG.balanceOf(dsaWallet0.address);
                expect(new_png_balance).to.be.gt(png_balance);
            });
        });

        describe("emergencyWithdrawLpStake function", function () {
            // Deposit LP again
            before(async () => {
                const spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "depositLpStake",
                        args: [
                            0,
                            lpAmount,
                            0,
                            0
                        ]
                    }
                ];
                await dsaWallet0.connect(wallet0).cast(
                    ...encodeSpells(spells),
                    wallet1.address
                )
            });

            it("Check if success in emergencyWithdrawLpStake", async function () {
                let balance = await pangolinLPToken.balanceOf(dsaWallet0.address);
                const amount = lpAmount.sub(balance)
                const spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "emergencyWithdrawLpStake",
                        args: [0]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.not.reverted;
                // Check if PNG/AVAX LP is equal 0
                balance = await pangolinLPToken.balanceOf(dsaWallet0.address);
                expect(balance).to.be.eq(lpAmount);
            });
        });
    });

    describe("Pangolin Staking - Single Stake Test (PNG)", function () {
        let pngToken: Contract;
        let stakingContract: Contract;
        let stakingBalance: BigNumber;
        before(async () => {
            const amount = ethers.utils.parseEther("100"); // 100 PNG
            const int_slippage = 0.03
    
            const PangolinRouterABI = [
                "function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts)"
            ];
    
            // Get amount of AVAX for 200 PNG from Pangolin
            const PangolinRouter = await ethers.getContractAt(
                PangolinRouterABI, 
                "0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106"
            );
            const amounts = await PangolinRouter.getAmountsOut(
                amount, 
                [
                    PNG_ADDRESS, 
                    WAVAX_ADDRESS
                ]
            );

            const amtA = amounts[0];
            const amtB = amounts[1];
            const unitAmt = (amtB * (1 + int_slippage)) / amtA;
            const unitAmount = ethers.utils.parseEther(unitAmt.toString());

            const spells = [
                {
                    connector: pangolinConnectorName,
                    method: "buy",
                    args: [
                        PNG_ADDRESS, 
                        "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", 
                        amount, 
                        unitAmount, 
                        0, 
                        0
                    ]
                }
            ];
            // Run spell transaction
            const tx = await dsaWallet0.connect(wallet0).cast(
                ...encodeSpells(spells), wallet1.address
            );
            const receipt = await tx.wait();

            pngToken = await ethers.getContractAt(abis.basic.erc20, PNG_ADDRESS);
            stakingContract = await ethers.getContractAt(abis.basic.erc20, PNG_STAKING_ADDRESS);
        });

        it("Check if has 100 PNG", async function () {
            const amount = ethers.utils.parseEther("100");
            const pngBalance = await pngToken.balanceOf(dsaWallet0.address);
            expect(pngBalance, `PNG Token is equal 100`).to.be.gt(amount.toString());
        });
    
        it("Check if some functions reverts by: Invalid amount, amount cannot be 0", async function () {
            const amount = 0;
            const getId = 0;
            const setId = 0;
            let spells = [
                {
                    connector: pangolinStakeConnectorName,
                    method: "depositPNGStake",
                    args: [
                        PNG_STAKING_ADDRESS, 
                        amount, 
                        getId, 
                        setId
                    ]
                }
            ];
            await expect(
                dsaWallet0.connect(wallet0).cast(
                  ...encodeSpells(spells),
                  wallet1.address
                )
            ).to.be.revertedWith("Invalid amount, amount cannot be 0");

            spells[0].method = "withdrawPNGStake"
            await expect(
                dsaWallet0.connect(wallet0).cast(
                  ...encodeSpells(spells),
                  wallet1.address
                )
            ).to.be.revertedWith("Invalid amount, amount cannot be 0");
        });

        describe("depositPNGStake function", function () {
            it("Check if reverts by: Invalid amount, amount greater than balance of PNG", async function () {
                const amount = ethers.utils.parseEther("200")
                let spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "depositPNGStake",
                        args: [
                            PNG_STAKING_ADDRESS, 
                            amount, 
                            0, 
                            0
                        ]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.revertedWith("Invalid amount, amount greater than balance of PNG");
            });

            it("Check if success in depositPNGStake", async function () {
                const amount = await pngToken.balanceOf(dsaWallet0.address);
                let spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "depositPNGStake",
                        args: [
                            PNG_STAKING_ADDRESS, 
                            amount, 
                            0, 
                            0
                        ]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.not.reverted;
                const new_png_balance = await pngToken.balanceOf(dsaWallet0.address);
                expect(new_png_balance).to.be.eq(0);
                const staking_balance = await stakingContract.balanceOf(dsaWallet0.address);
                expect(staking_balance).to.be.gt(0);
                stakingBalance = staking_balance
            });

            it("Check if reverts by: Invalid PNG balance", async function () {
                const amount = ethers.utils.parseEther("100")
                let spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "depositPNGStake",
                        args: [
                            PNG_STAKING_ADDRESS, 
                            amount, 
                            0, 
                            0
                        ]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.revertedWith("Invalid PNG balance");
            });
        });

        describe("withdrawPNGStake function", function () {
            it("Check if reverts by: Invalid amount, amount greater than balance of staking", async function () {
                const amount = ethers.utils.parseEther("200")
                let spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "withdrawPNGStake",
                        args: [
                            PNG_STAKING_ADDRESS, 
                            amount, 
                            0, 
                            0
                        ]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.revertedWith("Invalid amount, amount greater than balance of staking");
            });

            it("Check if success in withdrawPNGStake", async function () {
                const amount = ethers.utils.parseEther("50");
                let spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "withdrawPNGStake",
                        args: [
                            PNG_STAKING_ADDRESS, 
                            amount, 
                            0, 
                            0
                        ]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.not.reverted;

                const balance = await pngToken.balanceOf(dsaWallet0.address);
                expect(balance).to.be.eq(amount);
            });
        });

        describe("claimPNGStakeReward function", function () {
            it("Check if success in claimPNGStakeReward", async function () {
                // Increase Time in 20 seconds
                await hre.network.provider.send("evm_increaseTime", [20]);
                // Mine new block
                await hre.network.provider.send("evm_mine");
                const amount = ethers.utils.parseEther("50");
                let spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "claimPNGStakeReward",
                        args: [PNG_STAKING_ADDRESS]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.not.reverted;

                const balance = await pngToken.balanceOf(dsaWallet0.address);
                expect(balance).to.be.gt(amount);
            });

            it("Check if reverts by: No rewards to claim", async function () {
                let spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "claimPNGStakeReward",
                        args: [PNG_STAKING_ADDRESS]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.revertedWith("No rewards to claim");
            });
        });

        describe("exitPNGStake function", function () {
            it("Check if success in exitPNGStake", async function () {
                let spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "exitPNGStake",
                        args: [PNG_STAKING_ADDRESS]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.not.reverted;

                const balance = await stakingContract.balanceOf(dsaWallet0.address);
                expect(balance).to.be.eq(0);
            });

            it("Check if reverts by: No balance to exit", async function () {
                let spells = [
                    {
                        connector: pangolinStakeConnectorName,
                        method: "exitPNGStake",
                        args: [PNG_STAKING_ADDRESS]
                    }
                ];
                await expect(
                    dsaWallet0.connect(wallet0).cast(
                      ...encodeSpells(spells),
                      wallet1.address
                    )
                ).to.be.revertedWith("No balance to exit");
            });
        });
    });
});
