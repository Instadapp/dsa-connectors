//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./helpers.sol";
import "./events.sol";

/**
 * @title Morpho Rewards.
 * @dev Claim Morpho and Underlying Pool Rewards.
 */

abstract contract MorphoRewards is Helpers, Events {
	/**
	 * @dev Claim Pending MORPHO Rewards.
	 * @notice Claims rewards.
	 * @param _account The address of the claimer.
	 * @param _claimable The overall claimable amount of token rewards.
	 * @param _proof The merkle proof that validates this claim.
	 */
	function claimMorpho(
		address _account,
		uint256 _claimable,
		bytes32[] calldata _proof,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(_proof.length > 0, "proofs-empty");

		MORPHO_REWARDS.claim(_account, _claimable, _proof);

		setUint(_setId, _claimable);

		_eventName = "LogClaimedMorpho(address,uint256,uint256)";
		_eventParam = abi.encode(_account, _claimable, _setId);
	}

	/**
	 * @dev Claim Underlying Pool Rewards.
	 * @notice Claims rewards for the given assets.
	 * @param _poolTokenAddresses The cToken addresses to claim rewards from.
	 * @param _tradeForMorphoToken Whether or not to trade reward tokens for MORPHO tokens.
	 * @param _setId Set ID for claimed amount(in COMP).
	 */
	function claimCompound(
		address[] calldata _poolTokenAddresses,
		bool _tradeForMorphoToken,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amountOfRewards = MORPHO_COMPOUND.claimRewards(
			_poolTokenAddresses,
			_tradeForMorphoToken
		);

		setUint(_setId, _amountOfRewards);

		_eventName = "LogClaimedCompound(address[],bool,uint256,uint256)";
		_eventParam = abi.encode(
			_poolTokenAddresses,
			_tradeForMorphoToken,
			_amountOfRewards,
			_setId
		);
	}

	/**
	 * @dev Claim Underlying Pool Rewards.
	 * @notice Claims rewards for the given assets.
	 * @param _poolTokenAddresses The assets to claim rewards from (aToken or variable debt token).
	 * @param _tradeForMorphoToken Whether or not to trade reward tokens for MORPHO tokens.
	 * @param _setId Set ID for claimed amount(in reward token).
	 */
	function claimAave(
		address[] calldata _poolTokenAddresses,
		bool _tradeForMorphoToken,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amountOfRewards = MORPHO_AAVE.claimRewards(
			_poolTokenAddresses,
			_tradeForMorphoToken
		);

		setUint(_setId, _amountOfRewards);

		_eventName = "LogClaimedAave(address[],bool,uint256,uint256)";
		_eventParam = abi.encode(
			_poolTokenAddresses,
			_tradeForMorphoToken,
			_amountOfRewards,
			_setId
		);
	}
}

contract ConnectV2MorphoRewards is MorphoRewards {
	string public constant name = "Morpho-Rewards-v1.0";
}
