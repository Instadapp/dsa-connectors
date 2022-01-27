pragma solidity ^0.7.6;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";

import { TokenInterface } from "../../common/interfaces.sol";
import { ISavingsContractV2, IBoostedSavingsVault } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	address internal constant mUsdToken =
		0xe2f2a5C287993345a840Db3B0845fbC70f5935a5;
	address internal constant imUsdToken =
		0x30647a72Dc82d7Fbb1123EA74716aB8A317Eac19;
	address internal constant imUsdVault =
		0x78BefCa7de27d07DC6e71da295Cc2946681A6c7B;

	/***************************************
                    Internal
    ****************************************/

	/**
	 * @dev Deposit to Save from any asset
	 * @notice Called internally from deposit functions
	 * @param _token Address of token to deposit
	 * @param _amount Amount of token to deposit
	 * @param _path Path to mint mUSD (only needed for Feeder Pool)
	 * @param _stake stake token in Vault?
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function _deposit(
		address _token,
		uint256 _amount,
		address _path,
		bool _stake
	) internal returns (string memory _eventName, bytes memory _eventParam) {
		// 1. Deposit mUSD to Save
		approve(TokenInterface(mUsdToken), imUsdToken, _amount);
		uint256 credits = ISavingsContractV2(imUsdToken).depositSavings(
			_amount
		);

		if (_stake) {
			// 2. Stake imUSD to Vault
			approve(TokenInterface(imUsdToken), imUsdVault, credits);
			IBoostedSavingsVault(imUsdVault).stake(credits);
		}
		// 3. Log Events
		_eventName = "LogDeposit(address,uint256,address,bool)";
		_eventParam = abi.encode(_token, _amount, _path, _stake);
	}

	/**
	 * @dev Withdraws from Save
	 * @notice Withdraws token supported by mStable from Save
	 * @param _credits Credits to withdraw
	 * @param _unstake unstake from Vault?
	 * @return amountWithdrawn Amount withdrawn in mUSD
	 */

	function _withdraw(uint256 _credits, bool _unstake)
		internal
		returns (uint256 amountWithdrawn)
	{
		uint256 credits;
		// 1. Withdraw from Vault
		if (_unstake) {
			credits = _credits == uint256(-1)
				? TokenInterface(imUsdVault).balanceOf(address(this))
				: _credits;
			IBoostedSavingsVault(imUsdVault).withdraw(credits);
		}

		// 2. Withdraw from Save
		credits = _credits == uint256(-1)
			? TokenInterface(imUsdToken).balanceOf(address(this))
			: _credits;
		approve(TokenInterface(imUsdToken), imUsdVault, _credits);
		amountWithdrawn = ISavingsContractV2(imUsdToken).redeemCredits(credits);
	}

	/**
	 * @dev Returns the reward tokens
	 * @notice Gets the reward tokens from the vault contract
	 * @return rewardToken Address of reward token
	 */

	function _getRewardTokens() internal view returns (address rewardToken) {
		rewardToken = address(
			IBoostedSavingsVault(imUsdVault).getRewardToken()
		);
	}

	/**
	 * @dev Returns the internal balances of the rewardToken and platformToken
	 * @notice Gets current balances of rewardToken and platformToken, used for calculating rewards accrued
	 * @param _rewardToken Address of reward token
	 * @return a Amount of reward token
	 */

	function _getRewardInternalBal(address _rewardToken)
		internal
		view
		returns (uint256 a)
	{
		a = TokenInterface(_rewardToken).balanceOf(address(this));
	}
}
