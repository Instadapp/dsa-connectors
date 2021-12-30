pragma solidity ^0.7.6;

interface IMasset {
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

interface IBoostedSavingsVault {
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

	/**
	 * @dev Withdraws stake from pool and claims any unlocked rewards.
	 * Note, this function is costly - the args for _claimRewards
	 * should be determined off chain and then passed to other fn
	 */
	function exit() external;

	/**
	 * @dev Withdraws stake from pool and claims any unlocked rewards.
	 * @param _first    Index of the first array element to claim
	 * @param _last     Index of the last array element to claim
	 */
	function exit(uint256 _first, uint256 _last) external;

	/**
	 * @dev Withdraws given stake amount from the pool
	 * @param _amount Units of the staked token to withdraw
	 */
	function withdraw(uint256 _amount) external;

	/**
	 * @dev Claims only the tokens that have been immediately unlocked, not including
	 * those that are in the lockers.
	 */
	function claimReward() external;

	/**
	 * @dev Claims all unlocked rewards for sender.
	 * Note, this function is costly - the args for _claimRewards
	 * should be determined off chain and then passed to other fn
	 */
	function claimRewards() external;

	/**
	 * @dev Claims all unlocked rewards for sender. Both immediately unlocked
	 * rewards and also locked rewards past their time lock.
	 * @param _first    Index of the first array element to claim
	 * @param _last     Index of the last array element to claim
	 */
	function claimRewards(uint256 _first, uint256 _last) external;

	/**
	 * @dev Pokes a given account to reset the boost
	 */
	function pokeBoost(address _account) external;

	/**
	 * @dev Gets the RewardsToken
	 */
	function getRewardToken() external view returns (IERC20);

	/**
	 * @dev Gets the last applicable timestamp for this reward period
	 */
	function lastTimeRewardApplicable() external view returns (uint256);

	/**
	 * @dev Calculates the amount of unclaimed rewards per token since last update,
	 * and sums with stored to give the new cumulative reward per token
	 * @return 'Reward' per staked token
	 */
	function rewardPerToken() external view returns (uint256);

	/**
	 * @dev Returned the units of IMMEDIATELY claimable rewards a user has to receive. Note - this
	 * does NOT include the majority of rewards which will be locked up.
	 * @param _account User address
	 * @return Total reward amount earned
	 */
	function earned(address _account) external view returns (uint256);

	/**
	 * @dev Calculates all unclaimed reward data, finding both immediately unlocked rewards
	 * and those that have passed their time lock.
	 * @param _account User address
	 * @return amount Total units of unclaimed rewards
	 * @return first Index of the first userReward that has unlocked
	 * @return last Index of the last userReward that has unlocked
	 */
	function unclaimedRewards(address _account)
		external
		view
		returns (
			uint256 amount,
			uint256 first,
			uint256 last
		);
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

interface IERC20 {
	/**
	 * @dev Returns the amount of tokens in existence.
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Returns the amount of tokens owned by `account`.
	 */
	function balanceOf(address account) external view returns (uint256);

	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(address recipient, uint256 amount)
		external
		returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * IMPORTANT: Beware that changing an allowance with this method brings the risk
	 * that someone may use both the old and the new allowance by unfortunate
	 * transaction ordering. One possible solution to mitigate this race
	 * condition is to first reduce the spender's allowance to 0 and set the
	 * desired value afterwards:
	 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	 *
	 * Emits an {Approval} event.
	 */
	function approve(address spender, uint256 amount) external returns (bool);

	/**
	 * @dev Moves `amount` tokens from `sender` to `recipient` using the
	 * allowance mechanism. `amount` is then deducted from the caller's
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	/**
	 * @dev Emitted when `value` tokens are moved from one account (`from`) to
	 * another (`to`).
	 *
	 * Note that `value` may be zero.
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Emitted when the allowance of a `spender` for an `owner` is set by
	 * a call to {approve}. `value` is the new allowance.
	 */
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}
