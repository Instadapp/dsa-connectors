const TROVE_MANAGER_ADDRESS = "0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4bb2";
const TROVE_MANAGER_ABI = [
  "function getTroveColl(address _borrower) external view returns (uint)",
  "function getTroveDebt(address _borrower) external view returns (uint)",
  "function getTroveStatus(address _borrower) external view returns (uint)",
  "function redeemCollateral(uint _LUSDAmount, address _firstRedemptionHint, address _upperPartialRedemptionHint, address _lowerPartialRedemptionHint, uint _partialRedemptionHintNICR, uint _maxIterations, uint _maxFee) external returns (uint)",
  "function getNominalICR(address _borrower) external view returns (uint)",
  "function liquidate(address _borrower) external",
  "function liquidateTroves(uint _n) external",
];

const BORROWER_OPERATIONS_ADDRESS =
  "0x24179CD81c9e782A4096035f7eC97fB8B783e007";
const BORROWER_OPERATIONS_ABI = [
  "function openTrove(uint256 _maxFee, uint256 _LUSDAmount, address _upperHint, address _lowerHint) external payable",
  "function closeTrove() external",
];

const LUSD_TOKEN_ADDRESS = "0x5f98805A4E8be255a32880FDeC7F6728C6568bA0";
const LUSD_TOKEN_ABI = [
  "function transfer(address _to, uint256 _value) public returns (bool success)",
  "function balanceOf(address account) external view returns (uint256)",
  "function approve(address spender, uint256 amount) external returns (bool)",
];

const ACTIVE_POOL_ADDRESS = "0xDf9Eb223bAFBE5c5271415C75aeCD68C21fE3D7F";
const ACTIVE_POOL_ABI = ["function getLUSDDebt() external view returns (uint)"];

const PRICE_FEED_ADDRESS = "0x4c517D4e2C851CA76d7eC94B805269Df0f2201De";
const PRICE_FEED_ABI = ["function fetchPrice() external returns (uint)"];

const HINT_HELPERS_ADDRESS = "0xE84251b93D9524E0d2e621Ba7dc7cb3579F997C0";
const HINT_HELPERS_ABI = [
  "function getRedemptionHints(uint _LUSDamount, uint _price, uint _maxIterations) external view returns (address firstRedemptionHint, uint partialRedemptionHintNICR, uint truncatedLUSDamount)",
  "function getApproxHint(uint _CR, uint _numTrials, uint _inputRandomSeed) view returns (address hintAddress, uint diff, uint latestRandomSeed)",
  "function computeNominalCR(uint _coll, uint _debt) external pure returns (uint)",
];

const SORTED_TROVES_ADDRESS = "0x8FdD3fbFEb32b28fb73555518f8b361bCeA741A6";
const SORTED_TROVES_ABI = [
  "function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address)",
  "function getLast() external view returns (address)",
];

const STABILITY_POOL_ADDRESS = "0x66017D22b0f8556afDd19FC67041899Eb65a21bb";
const STABILITY_POOL_ABI = [
  "function getCompoundedLUSDDeposit(address _depositor) external view returns (uint)",
  "function getDepositorETHGain(address _depositor) external view returns (uint)",
];

const STAKING_ADDRESS = "0x4f9Fbb3f1E99B56e0Fe2892e623Ed36A76Fc605d";
const STAKING_ABI = [
  "function stake(uint _LQTYamount) external",
  "function unstake(uint _LQTYamount) external",
];

const LQTY_TOKEN_ADDRESS = "0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D";
const LQTY_TOKEN_ABI = [
  "function balanceOf(address account) external view returns (uint256)",
  "function transfer(address _to, uint256 _value) public returns (bool success)",
];

module.exports = {
  TROVE_MANAGER_ADDRESS,
  TROVE_MANAGER_ABI,
  BORROWER_OPERATIONS_ADDRESS,
  BORROWER_OPERATIONS_ABI,
  LUSD_TOKEN_ADDRESS,
  LUSD_TOKEN_ABI,
  STABILITY_POOL_ADDRESS,
  STABILITY_POOL_ABI,
  ACTIVE_POOL_ADDRESS,
  ACTIVE_POOL_ABI,
  PRICE_FEED_ADDRESS,
  PRICE_FEED_ABI,
  HINT_HELPERS_ADDRESS,
  HINT_HELPERS_ABI,
  SORTED_TROVES_ADDRESS,
  SORTED_TROVES_ABI,
  STAKING_ADDRESS,
  STAKING_ABI,
  LQTY_TOKEN_ADDRESS,
  LQTY_TOKEN_ABI,
};
