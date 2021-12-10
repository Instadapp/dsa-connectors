import hre from "hardhat";
import { ethers } from "hardhat";
import hardhatConfig from "../../../hardhat.config";

// Instadapp deployment and testing helpers
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector"
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2"
import { encodeSpells } from "../../../scripts/tests/encodeSpells"
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner"

// Instadapp addresses/ABIs
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";

// Instadapp Liquity Connector artifacts
import { ConnectV2Liquity__factory, ConnectV2Basic__factory } from "../../../typechain";

// Instadapp uses a fake address to represent native ETH
import { constants } from "../../../scripts/constant/constant";
import type { Signer, Contract, BigNumber } from "ethers";
const LIQUITY_CONNECTOR = "LIQUITY-v1-TEST";
const LUSD_GAS_COMPENSATION = hre.ethers.utils.parseUnits("200", 18); // 200 LUSD gas compensation repaid after loan repayment
const LIQUIDATABLE_TROVES_BLOCK_NUMBER = 12478159; // Deterministic block number for tests to run against, if you change this, tests will break.
const JUSTIN_SUN_ADDRESS = "0x903d12bf2c57a29f32365917c706ce0e1a84cce3"; // LQTY whale address
const LIQUIDATABLE_TROVE_ADDRESS = "0xafbeb4cb97f3b08ec2fe07ef0dac15d37013a347"; // Trove which is liquidatable at blockNumber: LIQUIDATABLE_TROVES_BLOCK_NUMBER
// @ts-ignore
const MAX_GAS = hardhatConfig.networks.hardhat.blockGasLimit ?? 12000000; // Maximum gas limit (12000000)
const INSTADAPP_BASIC_V1_CONNECTOR = "Basic-v1";
const ETH = constants.native_address

const openTroveSpell = async (
  dsa: any,
  signer: Signer,
  depositAmount: any,
  borrowAmount: any,
  upperHint: any,
  lowerHint: any,
  maxFeePercentage: any
) => {
  let address = await signer.getAddress();

  const openTroveSpell = {
    connector: LIQUITY_CONNECTOR,
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

  return await dsa
    .connect(signer)
    .cast(...encodeSpells([openTroveSpell]), address, {
      value: depositAmount,
    });
};

const createDsaTrove = async (
  dsa: any,
  signer: any,
  liquity: any,
  depositAmount = hre.ethers.utils.parseEther("5"),
  borrowAmount = hre.ethers.utils.parseUnits("2000", 18)
) => {
  const maxFeePercentage = hre.ethers.utils.parseUnits("0.5", 18); // 0.5% max fee
  const { upperHint, lowerHint } = await getTroveInsertionHints(
    depositAmount,
    borrowAmount,
    liquity
  );
  return await openTroveSpell(
    dsa,
    signer,
    depositAmount,
    borrowAmount,
    upperHint,
    lowerHint,
    maxFeePercentage
  );
};

const sendToken = async (token: any, amount: any, from: any, to: any) => {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [from],
  });
  const signer = hre.ethers.provider.getSigner(from);

  return await token.connect(signer).transfer(to, amount);
};

const resetInitialState = async (walletAddress: any, contracts: any, isDebug = false) => {
  const liquity = await deployAndConnect(contracts, isDebug);
  const dsa = await buildDSAv2(walletAddress);

  return [liquity, dsa];
};

const resetHardhatBlockNumber = async (blockNumber: number) => {
  return await hre.network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          // @ts-ignore
          jsonRpcUrl: hre.config.networks.hardhat.forking.url,
          blockNumber,
        },
      },
    ],
  });
};

const deployAndConnect = async (contracts: any, isDebug = false) => {
  // Pin Liquity tests to a particular block number to create deterministic state (Ether price etc.)
  await resetHardhatBlockNumber(LIQUIDATABLE_TROVES_BLOCK_NUMBER);
  type Liquidity = {
    troveManager: Contract,
    borrowerOperations: Contract,
    stabilityPool: Contract,
    lusdToken: Contract,
    lqtyToken: Contract,
    activePool: Contract,
    priceFeed: Contract,
    hintHelpers: Contract,
    sortedTroves: Contract,
    staking: Contract,
    collSurplus: Contract,
  };

  const liquity = {} as Liquidity

  const masterSigner = await getMasterSigner();
  const instaConnectorsV2 = await ethers.getContractAt(
    abis.core.connectorsV2,
    addresses.core.connectorsV2
  );
  const connector = await deployAndEnableConnector({
    connectorName: LIQUITY_CONNECTOR,
    contractArtifact: ConnectV2Liquity__factory,
    signer: masterSigner,
    connectors: instaConnectorsV2,
  });
  isDebug &&
    console.log(`${LIQUITY_CONNECTOR} Connector address`, connector.address);

  const basicConnector = await deployAndEnableConnector({
    connectorName: "Basic-v1",
    contractArtifact: ConnectV2Basic__factory,
    signer: masterSigner,
    connectors: instaConnectorsV2,
  });
  isDebug && console.log("Basic-v1 Connector address", basicConnector.address);

  liquity.troveManager = new ethers.Contract(
    contracts.TROVE_MANAGER_ADDRESS,
    contracts.TROVE_MANAGER_ABI,
    ethers.provider
  );

  liquity.borrowerOperations = new ethers.Contract(
    contracts.BORROWER_OPERATIONS_ADDRESS,
    contracts.BORROWER_OPERATIONS_ABI,
    ethers.provider
  );

  liquity.stabilityPool = new ethers.Contract(
    contracts.STABILITY_POOL_ADDRESS,
    contracts.STABILITY_POOL_ABI,
    ethers.provider
  );

  liquity.lusdToken = new ethers.Contract(
    contracts.LUSD_TOKEN_ADDRESS,
    contracts.LUSD_TOKEN_ABI,
    ethers.provider
  );

  liquity.lqtyToken = new ethers.Contract(
    contracts.LQTY_TOKEN_ADDRESS,
    contracts.LQTY_TOKEN_ABI,
    ethers.provider
  );

  liquity.activePool = new ethers.Contract(
    contracts.ACTIVE_POOL_ADDRESS,
    contracts.ACTIVE_POOL_ABI,
    ethers.provider
  );

  liquity.priceFeed = new ethers.Contract(
    contracts.PRICE_FEED_ADDRESS,
    contracts.PRICE_FEED_ABI,
    ethers.provider
  );

  liquity.hintHelpers = new ethers.Contract(
    contracts.HINT_HELPERS_ADDRESS,
    contracts.HINT_HELPERS_ABI,
    ethers.provider
  );

  liquity.sortedTroves = new ethers.Contract(
    contracts.SORTED_TROVES_ADDRESS,
    contracts.SORTED_TROVES_ABI,
    ethers.provider
  );

  liquity.staking = new ethers.Contract(
    contracts.STAKING_ADDRESS,
    contracts.STAKING_ABI,
    ethers.provider
  );
  liquity.collSurplus = new ethers.Contract(
    contracts.COLL_SURPLUS_ADDRESS,
    contracts.COLL_SURPLUS_ABI,
    ethers.provider
  );

  return liquity;
};

const getTroveInsertionHints = async (depositAmount: BigNumber, borrowAmount: BigNumber, liquity: any) => {
  const nominalCR = await liquity.hintHelpers.computeNominalCR(
    depositAmount,
    borrowAmount
  );

  const {
    hintAddress,
    latestRandomSeed,
  } = await liquity.hintHelpers.getApproxHint(nominalCR, 50, 1298379, {
    gasLimit: MAX_GAS,
  });
  randomSeed = latestRandomSeed;

  const {
    0: upperHint,
    1: lowerHint,
  } = await liquity.sortedTroves.findInsertPosition(
    nominalCR,
    hintAddress,
    hintAddress,
    {
      gasLimit: MAX_GAS,
    }
  );

  return {
    upperHint,
    lowerHint,
  };
};

let randomSeed = 4223;

const getRedemptionHints = async (amount: any, liquity: any) => {
  const ethPrice = await liquity.priceFeed.callStatic.fetchPrice();
  const [
    firstRedemptionHint,
    partialRedemptionHintNicr,
  ] = await liquity.hintHelpers.getRedemptionHints(amount, ethPrice, 0);

  const {
    hintAddress,
    latestRandomSeed,
  } = await liquity.hintHelpers.getApproxHint(
    partialRedemptionHintNicr,
    50,
    randomSeed,
    {
      gasLimit: MAX_GAS,
    }
  );
  randomSeed = latestRandomSeed;

  const {
    0: upperHint,
    1: lowerHint,
  } = await liquity.sortedTroves.findInsertPosition(
    partialRedemptionHintNicr,
    hintAddress,
    hintAddress,
    {
      gasLimit: MAX_GAS,
    }
  );

  return {
    partialRedemptionHintNicr,
    firstRedemptionHint,
    upperHint,
    lowerHint,
  };
};

const redeem = async (amount: any, from: any, wallet: { address: any; }, liquity: any) => {
  await sendToken(liquity.lusdToken, amount, from, wallet.address);
  const {
    partialRedemptionHintNicr,
    firstRedemptionHint,
    upperHint,
    lowerHint,
  } = await getRedemptionHints(amount, liquity);
  const maxFeePercentage = ethers.utils.parseUnits("0.5", 18); // 0.5% max fee

  return await liquity.troveManager
    .connect(wallet)
    .redeemCollateral(
      amount,
      firstRedemptionHint,
      upperHint,
      lowerHint,
      partialRedemptionHintNicr,
      0,
      maxFeePercentage,
      {
        gasLimit: MAX_GAS, // permit max gas
      }
    );
};

export default {
  deployAndConnect,
  resetInitialState,
  createDsaTrove,
  sendToken,
  getTroveInsertionHints,
  getRedemptionHints,
  redeem,
  LIQUITY_CONNECTOR,
  LUSD_GAS_COMPENSATION,
  JUSTIN_SUN_ADDRESS,
  LIQUIDATABLE_TROVE_ADDRESS,
  MAX_GAS,
  INSTADAPP_BASIC_V1_CONNECTOR,
  ETH,
};
