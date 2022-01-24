pragma solidity ^0.7.6;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";

import { ISavingsContractV2, IStakingRewardsWithPlatformToken } from "./interface.sol";
import { TokenInterface } from "../../common/interfaces.sol";

abstract contract Helpers is DSMath, Basic {
	address internal constant mUsdToken =
		0xE840B73E5287865EEc17d250bFb1536704B43B21;
	address internal constant imUsdToken =
		0x5290Ad3d83476CA6A2b178Cd9727eE1EF72432af;
	address internal constant imUsdVault =
		0x32aBa856Dc5fFd5A56Bcd182b13380e5C855aa29;

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
		_eventName = "LogDeposit(address,uint256,address)";
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
}
