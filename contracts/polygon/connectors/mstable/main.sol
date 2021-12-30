pragma solidity ^0.7.6;

/**
 * @title mStable SAVE.
 * @dev Depositing and withdrawing directly to Save
 */

import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { IMasset, ISavingsContractV2, IStakingRewardsWithPlatformToken, IFeederPool } from "./interface.sol";
import { TokenInterface } from "../../common/interfaces.sol";

import "hardhat/console.sol";

abstract contract mStableResolver is Events, Helpers {
	/***************************************
                    CORE
    ****************************************/

	/**
	 * @dev Deposit to Save via mUSD
	 * @notice Deposits token supported by mStable to Save
	 * @param _token Address of token to deposit
	 * @param _amount Amount of token to deposit
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function deposit(address _token, uint256 _amount)
		external
		returns (string memory _eventName, bytes memory _eventParam)
	{
		return _deposit(_token, _amount, imUsdToken);
	}

	/**
	 * @dev Deposit to Save via bAsset
	 * @notice Deposits token, requires _minOut for minting
	 * @param _token Address of token to deposit
	 * @param _amount Amount of token to deposit
	 * @param _minOut Minimum amount of token to mint
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function depositViaMint(
		address _token,
		uint256 _amount,
		uint256 _minOut
	) external returns (string memory _eventName, bytes memory _eventParam) {
		require(
			IMasset(mUsdToken).bAssetIndexes(_token) != 0,
			"Token not a bAsset"
		);

		approve(TokenInterface(_token), mUsdToken, _amount);
		uint256 mintedAmount = IMasset(mUsdToken).mint(
			_token,
			_amount,
			_minOut,
			address(this)
		);

		return _deposit(_token, mintedAmount, mUsdToken);
	}

	/**
	 * @dev Deposit to Save via feeder pool
	 * @notice Deposits token, requires _minOut for minting and _path
	 * @param _token Address of token to deposit
	 * @param _amount Amount of token to deposit
	 * @param _minOut Minimum amount of token to mint
	 * @param _path Feeder Pool address for _token
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function depositViaSwap(
		address _token,
		uint256 _amount,
		uint256 _minOut,
		address _path
	) external returns (string memory _eventName, bytes memory _eventParam) {
		require(_path != address(0), "Path must be set");
		require(
			IMasset(mUsdToken).bAssetIndexes(_token) == 0,
			"Token is bAsset"
		);

		approve(TokenInterface(_token), _path, _amount);
		uint256 mintedAmount = IFeederPool(_path).swap(
			_token,
			mUsdToken,
			_amount,
			_minOut,
			address(this)
		);
		return _deposit(_token, mintedAmount, _path);
	}

	/**
	 * @dev Withdraw from Save to mUSD
	 * @notice Withdraws from Save Vault to mUSD
	 * @param _credits Credits to withdraw
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */
	function withdraw(uint256 _credits)
		external
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 amountWithdrawn = _withdraw(_credits);

		_eventName = "LogWithdraw()";
		_eventParam = abi.encode(mUsdToken, amountWithdrawn, imUsdToken);
	}

	/**
	 * @dev Withdraw from Save to bAsset
	 * @notice Withdraws from Save Vault to bAsset
	 * @param _token bAsset to withdraw to
	 * @param _credits Credits to withdraw
	 * @param _minOut Minimum amount of token to mint
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function withdrawViaRedeem(
		address _token,
		uint256 _credits,
		uint256 _minOut
	) external returns (string memory _eventName, bytes memory _eventParam) {
		require(
			IMasset(mUsdToken).bAssetIndexes(_token) != 0,
			"Token not a bAsset"
		);

		uint256 amountWithdrawn = _withdraw(_credits);
		uint256 amountRedeemed = IMasset(mUsdToken).redeem(
			_token,
			amountWithdrawn,
			_minOut,
			address(this)
		);

		_eventName = "LogRedeem()";
		_eventParam = abi.encode(mUsdToken, amountRedeemed, _token);
	}

	/**
	 * @dev Withdraw from Save via Feeder Pool
	 * @notice Withdraws from Save Vault to asset via Feeder Pool
	 * @param _token bAsset to withdraw to
	 * @param _credits Credits to withdraw
	 * @param _minOut Minimum amount of token to mint
	 * @param _path Feeder Pool address for _token
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function withdrawViaSwap(
		address _token,
		uint256 _credits,
		uint256 _minOut,
		address _path
	) external returns (string memory _eventName, bytes memory _eventParam) {
		require(_path != address(0), "Path must be set");
		require(
			IMasset(mUsdToken).bAssetIndexes(_token) == 0,
			"Token is bAsset"
		);

		uint256 amountWithdrawn = _withdraw(_credits);

		approve(TokenInterface(mUsdToken), _path, amountWithdrawn);
		uint256 amountRedeemed = IFeederPool(_path).swap(
			mUsdToken,
			_token,
			amountWithdrawn,
			_minOut,
			address(this)
		);

		_eventName = "LogRedeem()";
		_eventParam = abi.encode(_token, amountRedeemed, _path);
	}

	/**
	 * @dev Claims Rewards
	 * @notice Claims accrued rewards from the Vault
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function claimRewards()
		external
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(address rewardToken, address platformToken) = _getRewardTokens();
		(uint256 rewardAmount, uint256 platformAmount) = _getRewardInternalBal(
			rewardToken,
			platformToken
		);

		IStakingRewardsWithPlatformToken(imUsdVault).claimReward();

		(
			uint256 rewardAmountUpdated,
			uint256 platformAmountUpdated
		) = _getRewardInternalBal(rewardToken, platformToken);

		uint256 claimedRewardToken = sub(rewardAmountUpdated, rewardAmount);

		uint256 claimedPlatformToken = sub(
			platformAmountUpdated,
			platformAmount
		);

		_eventName = "LogClaimRewards()";
		_eventParam = abi.encode(
			rewardToken,
			claimedRewardToken,
			platformToken,
			claimedPlatformToken
		);
	}

	/***************************************
                    Internal
    ****************************************/

	/**
	 * @dev Deposit to Save from any asset
	 * @notice Called internally from deposit functions
	 * @param _token Address of token to deposit
	 * @param _amount Amount of token to deposit
	 * @param _path Path to mint mUSD (only needed for Feeder Pool)
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function _deposit(
		address _token,
		uint256 _amount,
		address _path
	) internal returns (string memory _eventName, bytes memory _eventParam) {
		// 1. Deposit mUSD to Save
		approve(TokenInterface(mUsdToken), imUsdToken, _amount);
		uint256 credits = ISavingsContractV2(imUsdToken).depositSavings(
			_amount
		);

		// 2. Stake imUSD to Vault
		approve(TokenInterface(imUsdToken), imUsdVault, credits);
		IStakingRewardsWithPlatformToken(imUsdVault).stake(credits);

		// 3. Log Events
		_eventName = "LogDeposit()";
		_eventParam = abi.encode(_token, _amount, _path);
	}

	/**
	 * @dev Withdraws from Save
	 * @notice Withdraws token supported by mStable from Save
	 * @param _credits Credits to withdraw
	 * @return amountWithdrawn Amount withdrawn in mUSD
	 */

	function _withdraw(uint256 _credits)
		internal
		returns (uint256 amountWithdrawn)
	{
		// 1. Withdraw from Vault
		// approve(TokenInterface(imUsdVault), imUsdToken, _credits);
		IStakingRewardsWithPlatformToken(imUsdVault).withdraw(_credits);

		// 2. Withdraw from Save
		approve(TokenInterface(imUsdToken), imUsdVault, _credits);
		amountWithdrawn = ISavingsContractV2(imUsdToken).redeemCredits(
			_credits
		);
	}

	/**
	 * @dev Returns the reward tokens
	 * @notice Gets the reward tokens from the vault contract
	 * @return rewardToken Address of reward token
	 * @return platformToken Address of platform token
	 */

	function _getRewardTokens()
		internal
		returns (address rewardToken, address platformToken)
	{
		rewardToken = IStakingRewardsWithPlatformToken(imUsdVault)
			.getRewardToken();
		platformToken = IStakingRewardsWithPlatformToken(imUsdVault)
			.getPlatformToken();
	}

	/**
	 * @dev Returns the internal balances of the rewardToken and platformToken
	 * @notice Gets current balances of rewardToken and platformToken, used for calculating rewards accrued
	 * @param _rewardToken Address of reward token
	 * @param _platformToken Address of platform token
	 * @return a Amount of reward token
	 * @return b Amount of platform token
	 */

	function _getRewardInternalBal(address _rewardToken, address _platformToken)
		internal
		view
		returns (uint256 a, uint256 b)
	{
		a = TokenInterface(_rewardToken).balanceOf(address(this));
		b = TokenInterface(_platformToken).balanceOf(address(this));
	}

	/**
	 * @dev Swaps token supported by mStable for another token
	 * @notice Swaps token supported by mStable for another token
	 * @param _token Address of token to swap
	 * @param _amount Amount of token to swap
	 * @param _minOutput Minimum amount of token to swap
	 */

	// function swap(
	// 	address _token,
	// 	uint256 _amount,
	// 	uint256 _minOutput
	// ) external returns (string memory _eventName, bytes memory _eventParam);
	// TODO
	// function to support via Feeders or separate function?
}

contract ConnectV2mStable is mStableResolver {
	string public constant name = "mStable-Polygon-Connector-v1";
}
