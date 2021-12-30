pragma solidity ^0.7.6;

// TODO: Interfaces go here
// https://polygonscan.com/address/0xca9cf48ad534f1efa2b0f6923457f2953df86e0b#code
interface IMasset {
	// Mint
	function mint(
		address _input,
		uint256 _inputQuantity,
		uint256 _minOutputQuantity,
		address _recipient
	) external returns (uint256 mintOutput);

	function mintMulti(
		address[] calldata _inputs,
		uint256[] calldata _inputQuantities,
		uint256 _minOutputQuantity,
		address _recipient
	) external returns (uint256 mintOutput);

	function getMintOutput(address _input, uint256 _inputQuantity)
		external
		view
		returns (uint256 mintOutput);

	function getMintMultiOutput(
		address[] calldata _inputs,
		uint256[] calldata _inputQuantities
	) external view returns (uint256 mintOutput);

	// Swaps
	function swap(
		address _input,
		address _output,
		uint256 _inputQuantity,
		uint256 _minOutputQuantity,
		address _recipient
	) external returns (uint256 swapOutput);

	function getSwapOutput(
		address _input,
		address _output,
		uint256 _inputQuantity
	) external view returns (uint256 swapOutput);

	// Redemption
	function redeem(
		address _output,
		uint256 _mAssetQuantity,
		uint256 _minOutputQuantity,
		address _recipient
	) external returns (uint256 outputQuantity);

	function redeemMasset(
		uint256 _mAssetQuantity,
		uint256[] calldata _minOutputQuantities,
		address _recipient
	) external returns (uint256[] memory outputQuantities);

	function redeemExactBassets(
		address[] calldata _outputs,
		uint256[] calldata _outputQuantities,
		uint256 _maxMassetQuantity,
		address _recipient
	) external returns (uint256 mAssetRedeemed);

	function getRedeemOutput(address _output, uint256 _mAssetQuantity)
		external
		view
		returns (uint256 bAssetOutput);

	function getRedeemExactBassetsOutput(
		address[] calldata _outputs,
		uint256[] calldata _outputQuantities
	) external view returns (uint256 mAssetAmount);

	// Views
	// This return an index, could be used to check if it's part of the basket
	function bAssetIndexes(address) external view returns (uint8);

	function getPrice() external view returns (uint256 price, uint256 k);
}

interface ISavingsContractV2 {
	function depositInterest(uint256 _amount) external; // V1 & V2

	function depositSavings(uint256 _amount)
		external
		returns (uint256 creditsIssued); // V1 & V2

	function depositSavings(uint256 _amount, address _beneficiary)
		external
		returns (uint256 creditsIssued); // V2

	function redeemCredits(uint256 _amount)
		external
		returns (uint256 underlyingReturned); // V2

	function redeemUnderlying(uint256 _amount)
		external
		returns (uint256 creditsBurned); // V2

	function exchangeRate() external view returns (uint256); // V1 & V2

	function balanceOfUnderlying(address _user)
		external
		view
		returns (uint256 balance); // V2

	function underlyingToCredits(uint256 _credits)
		external
		view
		returns (uint256 underlying); // V2

	function creditsToUnderlying(uint256 _underlying)
		external
		view
		returns (uint256 credits); // V2
}

interface IStakingRewardsWithPlatformToken {
	/**
	 * @dev Stakes a given amount of the StakingToken for the sender
	 * @param _amount Units of StakingToken
	 */
	function stake(uint256 _amount) external;

	/**
	 * @dev Stakes a given amount of the StakingToken for a given beneficiary
	 * @param _beneficiary Staked tokens are credited to this address
	 * @param _amount      Units of StakingToken
	 */
	function stake(address _beneficiary, uint256 _amount) external;

	function exit() external;

	/**
	 * @dev Withdraws given stake amount from the pool
	 * @param _amount Units of the staked token to withdraw
	 */
	function withdraw(uint256 _amount) external;

	/**
	 * @dev Claims outstanding rewards (both platform and native) for the sender.
	 * First updates outstanding reward allocation and then transfers.
	 */
	function claimReward() external;

	/**
	 * @dev Claims outstanding rewards for the sender. Only the native
	 * rewards token, and not the platform rewards
	 */
	function claimRewardOnly() external;

	function getRewardToken() external returns (address token);

	function getPlatformToken() external returns (address token);
}

abstract contract IFeederPool {
	// Mint
	function mint(
		address _input,
		uint256 _inputQuantity,
		uint256 _minOutputQuantity,
		address _recipient
	) external virtual returns (uint256 mintOutput);

	function mintMulti(
		address[] calldata _inputs,
		uint256[] calldata _inputQuantities,
		uint256 _minOutputQuantity,
		address _recipient
	) external virtual returns (uint256 mintOutput);

	function getMintOutput(address _input, uint256 _inputQuantity)
		external
		view
		virtual
		returns (uint256 mintOutput);

	function getMintMultiOutput(
		address[] calldata _inputs,
		uint256[] calldata _inputQuantities
	) external view virtual returns (uint256 mintOutput);

	// Swaps
	function swap(
		address _input,
		address _output,
		uint256 _inputQuantity,
		uint256 _minOutputQuantity,
		address _recipient
	) external virtual returns (uint256 swapOutput);

	function getSwapOutput(
		address _input,
		address _output,
		uint256 _inputQuantity
	) external view virtual returns (uint256 swapOutput);

	// Redemption
	function redeem(
		address _output,
		uint256 _fpTokenQuantity,
		uint256 _minOutputQuantity,
		address _recipient
	) external virtual returns (uint256 outputQuantity);

	function redeemProportionately(
		uint256 _fpTokenQuantity,
		uint256[] calldata _minOutputQuantities,
		address _recipient
	) external virtual returns (uint256[] memory outputQuantities);

	function redeemExactBassets(
		address[] calldata _outputs,
		uint256[] calldata _outputQuantities,
		uint256 _maxMassetQuantity,
		address _recipient
	) external virtual returns (uint256 mAssetRedeemed);

	function getRedeemOutput(address _output, uint256 _fpTokenQuantity)
		external
		view
		virtual
		returns (uint256 bAssetOutput);

	function getRedeemExactBassetsOutput(
		address[] calldata _outputs,
		uint256[] calldata _outputQuantities
	) external view virtual returns (uint256 mAssetAmount);

	// Views
	function mAsset() external view virtual returns (address);

	function getPrice() public view virtual returns (uint256 price, uint256 k);
}
