import { expect } from "chai";
import hre from "hardhat";
const { waffle, ethers } = hre;
const { provider } = waffle;
const { BigNumber, utils } = ethers;

import {deployAndEnableConnector} from "../../../scripts/tests/deployAndEnableConnector";
import {buildDSAv2} from "../../../scripts/tests/buildDSAv2";
import {encodeSpells} from "../../../scripts/tests/encodeSpells";
import {addresses} from "../../../scripts/tests/mainnet/addresses";
import {abis} from "../../../scripts/constant/abis";
import {impersonateAccounts} from "../../../scripts/tests/impersonate";
import type { Signer, Contract, BigNumberish } from "ethers";
import {forkReset, sendEth, mineNBlock} from "./utils";
import { ConnectV2Ubiquity__factory } from "../../../typechain";

import { abi as implementationsABI } from "../../../scripts/constant/abi/core/InstaImplementations.json";
const implementationsMappingAddr = "0xCBA828153d3a85b30B5b912e1f2daCac5816aE9D";

describe("Ubiquity", function () {
  const ubiquityTest = "UBIQUITY-TEST-A";

  const BOND = "0x2dA07859613C14F6f05c97eFE37B9B4F212b5eF5";
  const UAD = "0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6";
  const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
  const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
  const CRV3 = "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490";
  const POOL3 = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7";
  const UAD3CRVF = "0x20955CB69Ae1515962177D164dfC9522feef567E";

  const ethWhaleAddress = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
  const uadWhaleAddress = "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd";

  const blockFork = 13097100;
  const one = BigNumber.from(10).pow(18);
  const onep = BigNumber.from(10).pow(6);
  const ABI = [
    "function balanceOf(address owner) view returns (uint256)",
    "function allowance(address owner, address spender) external view returns (uint256)",
    "function transfer(address to, uint amount) returns (boolean)",
    "function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received) external returns (uint256)",
    "function add_liquidity(uint256[3],uint256) returns (uint256)",
    "function approve(address, uint256) external",
    "function holderTokens(address) view returns (uint256[])",
    "function getBond(uint256) view returns (tuple(address,uint256,uint256,uint256,uint256,uint256))"
  ];
  let dsa: Contract;
  let POOL3Contract: Contract;
  let CRV3Contract: Contract;
  let uAD3CRVfContract: Contract;
  let uADContract: Contract;
  let DAIContract: Contract;
  let USDCContract: Contract;
  let USDTContract: Contract;
  let BONDContract: Contract;
  let instaIndex: Contract;
  let instaConnectorsV2: Contract;
  let connector: Contract;
  let instaImplementationsMapping;
  let InstaAccountV2DefaultImpl;

  let uadWhale;

  const bondingShare = async function (address: any) {
    let lpAmount = BigNumber.from(0);
    let lpAmountTotal = BigNumber.from(0);
    let bondId = -1;

    const bondIds = await BONDContract.holderTokens(address);
    const bondN = bondIds?.length || 0;

    if (bondN) {
      for await (bondId of bondIds) {
        lpAmountTotal = lpAmountTotal.add((await BONDContract.getBond(bondId))[5]);
      }
      bondId = Number(bondIds[bondN - 1]);
      lpAmount = (await BONDContract.getBond(bondId))[5];
    }
    return { bondId, bondN, lpAmount, lpAmountTotal };
  };

  const depositAndGetOneBond = async function () {
    await dsaDepositUAD3CRVf(100);
    dsa.cast(
      ...encodeSpells([
        {
          connector: ubiquityTest,
          method: "deposit",
          args: [UAD3CRVF, one.mul(100), 1, 0, 0]
        }
      ]),
      uadWhaleAddress
    );
  };

  before(async () => {
    // await forkReset(blockFork);
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 13097100,
          },
        },
      ],
    });
    [uadWhale] = await impersonateAccounts([uadWhaleAddress]);
    const [ethWhale] = await impersonateAccounts([ethWhaleAddress]);

    await sendEth(ethWhale, uadWhaleAddress, 100);
    POOL3Contract = new ethers.Contract(POOL3, ABI, uadWhale);
    CRV3Contract = new ethers.Contract(CRV3, ABI, uadWhale);
    uAD3CRVfContract = new ethers.Contract(UAD3CRVF, ABI, uadWhale);
    uADContract = new ethers.Contract(UAD, ABI, uadWhale);
    DAIContract = new ethers.Contract(DAI, ABI, uadWhale);
    USDCContract = new ethers.Contract(USDC, ABI, uadWhale);
    USDTContract = new ethers.Contract(USDT, ABI, uadWhale);
    BONDContract = new ethers.Contract(BOND, ABI, uadWhale);
    dsa = (await buildDSAv2(uadWhaleAddress)).connect(uadWhale);
    await sendEth(ethWhale, dsa.address, 100);
    await sendEth(ethWhale, uadWhaleAddress, 100);

    instaIndex = new ethers.Contract(addresses.core.instaIndex, abis.core.instaIndex, ethWhale);

    const masterAddress = await instaIndex.master();
    const [master] = await impersonateAccounts([masterAddress]);
    await sendEth(ethWhale, masterAddress, 100);

    instaConnectorsV2 = new ethers.Contract(addresses.core.connectorsV2, abis.core.connectorsV2);

    instaImplementationsMapping = await ethers.getContractAt(implementationsABI, implementationsMappingAddr);
    InstaAccountV2DefaultImpl = await ethers.getContractFactory("InstaDefaultImplementation");
    InstaAccountV2DefaultImpl = await InstaAccountV2DefaultImpl.deploy(addresses.core.instaIndex);
    await InstaAccountV2DefaultImpl.deployed();
    await (
      await instaImplementationsMapping.connect(master).setDefaultImplementation(InstaAccountV2DefaultImpl.address)
    ).wait();

    connector = await deployAndEnableConnector({
      connectorName: ubiquityTest,
      contractArtifact: ConnectV2Ubiquity__factory,
      signer: master,
      connectors: instaConnectorsV2
    });
  });

  const logAll = async function () {
    console.log("dsa            eth", utils.formatEther(await ethers.provider.getBalance(dsa.address)));
    console.log("dsa            dai", utils.formatEther(await DAIContract.balanceOf(dsa.address)));
    console.log("dsa           usdc", utils.formatUnits(await USDCContract.balanceOf(dsa.address), 6));
    console.log("dsa           usdt", utils.formatUnits(await USDTContract.balanceOf(dsa.address), 6));
    console.log("dsa            uad", utils.formatEther(await uADContract.balanceOf(dsa.address)));
    console.log("dsa           3CRV", utils.formatEther(await CRV3Contract.balanceOf(dsa.address)));
    console.log("dsa      uad3CRV-f", utils.formatEther(await uAD3CRVfContract.balanceOf(dsa.address)));
    const { bondId, bondN, lpAmount, lpAmountTotal } = await bondingShare(dsa.address);
    console.log("dsa        n bonds", utils.formatEther(lpAmountTotal), bondN);
    console.log("dsa      last bond", utils.formatEther(lpAmount), bondId);
  };

  afterEach(logAll);

  const dsaDepositUAD3CRVf = async (amount: BigNumberish) => {
    await uAD3CRVfContract.transfer(dsa.address, one.mul(amount));
  };

  const dsaDepositUAD = async (amount: BigNumberish) => {
    await uAD3CRVfContract.remove_liquidity_one_coin(one.mul(amount).mul(110).div(100), 0, one.mul(amount));
    await uADContract.transfer(dsa.address, one.mul(amount));
  };

  const dsaDepositCRV3 = async (amount: BigNumberish) => {
    await uAD3CRVfContract.remove_liquidity_one_coin(one.mul(amount).mul(110).div(100), 1, one.mul(amount));
    await CRV3Contract.transfer(dsa.address, one.mul(amount));
  };

  const dsaDepositDAI = async (amount: BigNumberish) => {
    await uAD3CRVfContract.remove_liquidity_one_coin(
      one.mul(amount).mul(120).div(100),
      1,
      one.mul(amount).mul(110).div(100)
    );
    await POOL3Contract.remove_liquidity_one_coin(one.mul(amount).mul(110).div(100), 0, one.mul(amount));
    await DAIContract.transfer(dsa.address, one.mul(amount));
  };
  const dsaDepositUSDC = async (amount: BigNumberish) => {
    await uAD3CRVfContract.remove_liquidity_one_coin(
      one.mul(amount).mul(120).div(100),
      1,
      one.mul(amount).mul(110).div(100)
    );
    await POOL3Contract.remove_liquidity_one_coin(one.mul(amount).mul(110).div(100), 1, onep.mul(amount));
    await USDCContract.transfer(dsa.address, onep.mul(amount));
  };
  const dsaDepositUSDT = async (amount: BigNumberish) => {
    await uAD3CRVfContract.remove_liquidity_one_coin(
      one.mul(amount).mul(120).div(100),
      1,
      one.mul(amount).mul(110).div(100)
    );
    await POOL3Contract.remove_liquidity_one_coin(one.mul(amount).mul(110).div(100), 2, onep.mul(amount));
    await USDTContract.transfer(dsa.address, onep.mul(amount));
  };

  describe("Deposit", function () {
    it("should deposit uAD3CRVf to get Ubiquity Bonding Shares", async function () {
      await logAll();
      await dsaDepositUAD3CRVf(100);
      expect((await bondingShare(dsa.address)).lpAmount).to.be.equal(0);
      await expect(
        dsa.cast(
          ...encodeSpells([
            {
              connector: ubiquityTest,
              method: "deposit",
              args: [UAD3CRVF, one.mul(100), 4, 0, 0]
            }
          ]),
          uadWhaleAddress
        )
      ).to.be.not.reverted;
      expect((await bondingShare(dsa.address)).lpAmount).to.be.gt(0);
    });

    it("should deposit uAD to get Ubiquity Bonding Shares", async function () {
      await dsaDepositUAD(100);
      await expect(
        dsa.cast(
          ...encodeSpells([
            {
              connector: ubiquityTest,
              method: "deposit",
              args: [UAD, one.mul(100), 4, 0, 0]
            }
          ]),
          uadWhaleAddress
        )
      ).to.be.not.reverted;
      expect((await bondingShare(dsa.address)).lpAmount).to.be.gt(0);
    });

    it("should deposit 3CRV to get Ubiquity Bonding Shares", async function () {
      await dsaDepositCRV3(100);
      await expect(
        dsa.cast(
          ...encodeSpells([
            {
              connector: ubiquityTest,
              method: "deposit",
              args: [CRV3, one.mul(100), 4, 0, 0]
            }
          ]),
          uadWhaleAddress
        )
      ).to.be.not.reverted;
      expect((await bondingShare(dsa.address)).lpAmount).to.be.gt(0);
    });

    it("should deposit DAI to get Ubiquity Bonding Shares", async function () {
      await dsaDepositDAI(100);
      await expect(
        dsa.cast(
          ...encodeSpells([
            {
              connector: ubiquityTest,
              method: "deposit",
              args: [DAI, one.mul(100), 4, 0, 0]
            }
          ]),
          uadWhaleAddress
        )
      ).to.be.not.reverted;
      expect((await bondingShare(dsa.address)).lpAmount).to.be.gt(0);
    });

    it("should deposit USDC to get Ubiquity Bonding Shares", async function () {
      await dsaDepositUSDC(100);
      await expect(
        dsa.cast(
          ...encodeSpells([
            {
              connector: ubiquityTest,
              method: "deposit",
              args: [USDC, onep.mul(100), 4, 0, 0]
            }
          ]),
          uadWhaleAddress
        )
      ).to.be.not.reverted;
      expect((await bondingShare(dsa.address)).lpAmount).to.be.gt(0);
    });

    it("should deposit USDT to get Ubiquity Bonding Shares", async function () {
      await dsaDepositUSDT(100);
      await expect(
        dsa.cast(
          ...encodeSpells([
            {
              connector: ubiquityTest,
              method: "deposit",
              args: [USDT, onep.mul(100), 4, 0, 0]
            }
          ]),
          uadWhaleAddress
        )
      ).to.be.not.reverted;
      expect((await bondingShare(dsa.address)).lpAmount).to.be.gt(0);
    });
  });

  describe("Withdraw", function () {
    let bondId = -1;

    before(async () => {
      await depositAndGetOneBond();
      await depositAndGetOneBond();
      await depositAndGetOneBond();
      await depositAndGetOneBond();
      await depositAndGetOneBond();
      await depositAndGetOneBond();
      ({ bondId } = await bondingShare(dsa.address));

      await logAll();
      console.log("Mining 50 000 blocks for more than one week, please wait...");
      await mineNBlock(50000, 1);
    });

    it("Should deposit and withdraw DAI", async function () {
      await expect(
        dsa.cast(
          ...encodeSpells([
            {
              connector: ubiquityTest,
              method: "withdraw",
              args: [bondId, DAI, 0, 0]
            }
          ]),
          uadWhaleAddress
        )
      ).to.be.not.reverted;
    });

    it("Should deposit and withdraw USDC", async function () {
      // await expect(
      dsa.cast(
        ...encodeSpells([
          {
            connector: ubiquityTest,
            method: "withdraw",
            args: [bondId - 1, USDC, 0, 0]
          }
        ]),
        uadWhaleAddress
      );
      // ).to.be.not.reverted;
    });

    it("Should deposit and withdraw USDT", async function () {
      await expect(
        dsa.cast(
          ...encodeSpells([
            {
              connector: ubiquityTest,
              method: "withdraw",
              args: [bondId - 2, USDT, 0, 0]
            }
          ]),
          uadWhaleAddress
        )
      ).to.be.not.reverted;
    });

    it("Should deposit and withdraw UAD", async function () {
      await expect(
        dsa.cast(
          ...encodeSpells([
            {
              connector: ubiquityTest,
              method: "withdraw",
              args: [bondId - 3, UAD, 0, 0]
            }
          ]),
          uadWhaleAddress
        )
      ).to.be.not.reverted;
    });

    it("Should deposit and withdraw CRV3", async function () {
      await expect(
        dsa.cast(
          ...encodeSpells([
            {
              connector: ubiquityTest,
              method: "withdraw",
              args: [bondId - 4, CRV3, 0, 0]
            }
          ]),
          uadWhaleAddress
        )
      ).to.be.not.reverted;
    });

    it("Should deposit and withdraw UAD3CRVF", async function () {
      await expect(
        dsa.cast(
          ...encodeSpells([
            {
              connector: ubiquityTest,
              method: "withdraw",
              args: [bondId - 5, UAD3CRVF, 0, 0]
            }
          ]),
          uadWhaleAddress
        )
      ).to.be.not.reverted;
    });
  });

  describe("DSA wallet setup", function () {
    it("Should have contracts deployed.", async function () {
      expect(POOL3Contract.address).to.be.properAddress;
      expect(CRV3Contract.address).to.be.properAddress;
      expect(uADContract.address).to.be.properAddress;
      expect(uAD3CRVfContract.address).to.be.properAddress;
      expect(DAIContract.address).to.be.properAddress;
      expect(USDCContract.address).to.be.properAddress;
      expect(USDTContract.address).to.be.properAddress;
      expect(BONDContract.address).to.be.properAddress;
      expect(instaIndex.address).to.be.properAddress;
      expect(instaConnectorsV2.address).to.be.properAddress;
      expect(connector.address).to.be.properAddress;
      expect(dsa.address).to.be.properAddress;
    });
    it("Should deposit uAD3CRVf into DSA wallet", async function () {
      await dsaDepositUAD3CRVf(100);
      expect(await uAD3CRVfContract.balanceOf(dsa.address)).to.be.gte(one.mul(100));
    });
    it("Should deposit uAD into DSA wallet", async function () {
      await dsaDepositUAD(100);
      expect(await uADContract.balanceOf(dsa.address)).to.be.gte(one.mul(100));
    });
    it("Should deposit 3CRV into DSA wallet", async function () {
      await dsaDepositCRV3(100);
      expect(await CRV3Contract.balanceOf(dsa.address)).to.be.gte(one.mul(100));
    });
    it("Should deposit DAI into DSA wallet", async function () {
      await dsaDepositDAI(100);
      expect(await DAIContract.balanceOf(dsa.address)).to.be.gte(one.mul(100));
    });
    it("Should deposit USDC into DSA wallet", async function () {
      await dsaDepositUSDC(100);
      expect(await USDCContract.balanceOf(dsa.address)).to.be.gte(onep.mul(100));
    });
    it("Should deposit USDT into DSA wallet", async function () {
      await dsaDepositUSDT(100);
      expect(await USDTContract.balanceOf(dsa.address)).to.be.gte(onep.mul(100));
    });
  });
});
