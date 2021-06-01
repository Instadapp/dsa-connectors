const hre = require("hardhat");
const hardhatConfig = require("../../hardhat.config");

// Instadapp deployment and testing helpers
const deployAndEnableConnector = require("../../scripts/deployAndEnableConnector.js");
const encodeSpells = require("../../scripts/encodeSpells.js");
const getMasterSigner = require("../../scripts/getMasterSigner");

// Instadapp instadappAddresses/ABIs
const instadappAddresses = require("../../scripts/constant/addresses");
const instadappAbi = require("../../scripts/constant/abis");

// Instadapp Liquity Connector artifacts
const connectV2LiquityArtifacts = require("../../artifacts/contracts/mainnet/connectors/liquity/main.sol/ConnectV2Liquity.json");
const connectV2BasicV1Artifacts = require("../../artifacts/contracts/mainnet/connectors/basic/main.sol/ConnectV2Basic.json");

const CONNECTOR_NAME = "LIQUITY-v1-TEST";
const LUSD_GAS_COMPENSATION = hre.ethers.utils.parseUnits("200", 18); // 200 LUSD gas compensation repaid after loan repayment
const BLOCK_NUMBER = 12478159; // Deterministic block number for tests to run against, if you change this, tests will break.
const JUSTIN_SUN_ADDRESS = "0x903d12bf2c57a29f32365917c706ce0e1a84cce3"; // LQTY whale address
const LIQUIDATABLE_TROVE_ADDRESS = "0xafbeb4cb97f3b08ec2fe07ef0dac15d37013a347"; // Trove which is liquidatable at blockNumber: BLOCK_NUMBER
const MAX_GAS = hardhatConfig.networks.hardhat.blockGasLimit; // Maximum gas limit (12000000)

const openTroveSpell = async (
  dsa,
  signer,
  depositAmount,
  borrowAmount,
  upperHint,
  lowerHint,
  maxFeePercentage
) => {
  let address = signer.address;
  if (signer.address === undefined) {
    address = await signer.getAddress();
  }

  const openTroveSpell = {
    connector: CONNECTOR_NAME,
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
  const openTx = await dsa
    .connect(signer)
    .cast(...encodeSpells([openTroveSpell]), address, {
      value: depositAmount,
    });
  return await openTx.wait();
};

const createDsaTrove = async (
  dsa,
  signer,
  hintHelpers,
  sortedTroves,
  depositAmount = hre.ethers.utils.parseEther("5"),
  borrowAmount = hre.ethers.utils.parseUnits("2000", 18)
) => {
  const maxFeePercentage = hre.ethers.utils.parseUnits("0.5", 18); // 0.5% max fee
  const { upperHint, lowerHint } = await getTroveInsertionHints(
    depositAmount,
    borrowAmount,
    hintHelpers,
    sortedTroves
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

const sendToken = async (token, amount, from, to) => {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [from],
  });
  const signer = await hre.ethers.provider.getSigner(from);

  return await token.connect(signer).transfer(to, amount);
};

const resetHardhatBlockNumber = async (blockNumber) => {
  return await hre.network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: hardhatConfig.networks.hardhat.forking.url,
          blockNumber,
        },
      },
    ],
  });
};

const deployAndConnect = async (contracts, isDebug = false) => {
  // Pin Liquity tests to a particular block number to create deterministic state (Ether price etc.)
  await resetHardhatBlockNumber(BLOCK_NUMBER);

  const liquity = {
    troveManager: null,
    borrowerOperations: null,
    stabilityPool: null,
    lusdToken: null,
    lqtyToken: null,
    activePool: null,
    priceFeed: null,
    hintHelpers: null,
    sortedTroves: null,
    staking: null,
  };

  const masterSigner = await getMasterSigner();
  const instaConnectorsV2 = await ethers.getContractAt(
    instadappAbi.core.connectorsV2,
    instadappAddresses.core.connectorsV2
  );
  const connector = await deployAndEnableConnector({
    connectorName: CONNECTOR_NAME,
    contractArtifact: connectV2LiquityArtifacts,
    signer: masterSigner,
    connectors: instaConnectorsV2,
  });
  isDebug &&
    console.log(`${CONNECTOR_NAME} Connector address`, connector.address);

  const basicConnector = await deployAndEnableConnector({
    connectorName: "Basic-v1",
    contractArtifact: connectV2BasicV1Artifacts,
    signer: masterSigner,
    connectors: instaConnectorsV2,
  });
  isDebug && console.log("Basic-v1 Connector address", basicConnector.address);

  liquity.troveManager = new ethers.Contract(
    contracts.TROVE_MANAGER_ADDRESS,
    contracts.TROVE_MANAGER_ABI,
    ethers.provider
  );
  isDebug &&
    console.log("TroveManager contract address", liquity.troveManager.address);

  liquity.borrowerOperations = new ethers.Contract(
    contracts.BORROWER_OPERATIONS_ADDRESS,
    contracts.BORROWER_OPERATIONS_ABI,
    ethers.provider
  );
  isDebug &&
    console.log(
      "BorrowerOperations contract address",
      liquity.borrowerOperations.address
    );

  liquity.stabilityPool = new ethers.Contract(
    contracts.STABILITY_POOL_ADDRESS,
    contracts.STABILITY_POOL_ABI,
    ethers.provider
  );
  isDebug &&
    console.log(
      "StabilityPool contract address",
      liquity.stabilityPool.address
    );

  liquity.lusdToken = new ethers.Contract(
    contracts.LUSD_TOKEN_ADDRESS,
    contracts.LUSD_TOKEN_ABI,
    ethers.provider
  );
  isDebug &&
    console.log("LusdToken contract address", liquity.lusdToken.address);

  liquity.lqtyToken = new ethers.Contract(
    contracts.LQTY_TOKEN_ADDRESS,
    contracts.LQTY_TOKEN_ABI,
    ethers.provider
  );
  isDebug &&
    console.log("LqtyToken contract address", liquity.lqtyToken.address);

  liquity.activePool = new ethers.Contract(
    contracts.ACTIVE_POOL_ADDRESS,
    contracts.ACTIVE_POOL_ABI,
    ethers.provider
  );
  isDebug &&
    console.log("ActivePool contract address", liquity.activePool.address);

  liquity.priceFeed = new ethers.Contract(
    contracts.PRICE_FEED_ADDRESS,
    contracts.PRICE_FEED_ABI,
    ethers.provider
  );
  isDebug &&
    console.log("PriceFeed contract address", liquity.priceFeed.address);

  liquity.hintHelpers = new ethers.Contract(
    contracts.HINT_HELPERS_ADDRESS,
    contracts.HINT_HELPERS_ABI,
    ethers.provider
  );
  isDebug &&
    console.log("HintHelpers contract address", liquity.hintHelpers.address);

  liquity.sortedTroves = new ethers.Contract(
    contracts.SORTED_TROVES_ADDRESS,
    contracts.SORTED_TROVES_ABI,
    ethers.provider
  );
  isDebug &&
    console.log("SortedTroves contract address", liquity.sortedTroves.address);

  liquity.staking = new ethers.Contract(
    contracts.STAKING_ADDRESS,
    contracts.STAKING_ABI,
    ethers.provider
  );
  isDebug && console.log("Staking contract address", liquity.staking.address);

  return liquity;
};

const getTroveInsertionHints = async (
  depositAmount,
  borrowAmount,
  hintHelpers,
  sortedTroves
) => {
  const nominalCR = await hintHelpers.computeNominalCR(
    depositAmount,
    borrowAmount
  );

  const { hintAddress, latestRandomSeed } = await hintHelpers.getApproxHint(
    nominalCR,
    50,
    1298379,
    {
      gasLimit: MAX_GAS,
    }
  );
  randomSeed = latestRandomSeed;

  const { 0: upperHint, 1: lowerHint } = await sortedTroves.findInsertPosition(
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

const getRedemptionHints = async (
  amount,
  hintHelpers,
  sortedTroves,
  priceFeed
) => {
  const ethPrice = await priceFeed.callStatic.fetchPrice();
  const [
    firstRedemptionHint,
    partialRedemptionHintNicr,
  ] = await hintHelpers.getRedemptionHints(amount, ethPrice, 0);

  const { hintAddress, latestRandomSeed } = await hintHelpers.getApproxHint(
    partialRedemptionHintNicr,
    50,
    randomSeed,
    {
      gasLimit: MAX_GAS,
    }
  );
  randomSeed = latestRandomSeed;

  const { 0: upperHint, 1: lowerHint } = await sortedTroves.findInsertPosition(
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

module.exports = {
  deployAndConnect,
  createDsaTrove,
  openTroveSpell,
  sendToken,
  CONNECTOR_NAME,
  LUSD_GAS_COMPENSATION,
  BLOCK_NUMBER,
  JUSTIN_SUN_ADDRESS,
  LIQUIDATABLE_TROVE_ADDRESS,
  MAX_GAS,
  resetHardhatBlockNumber,
  getTroveInsertionHints,
  getRedemptionHints,
};
