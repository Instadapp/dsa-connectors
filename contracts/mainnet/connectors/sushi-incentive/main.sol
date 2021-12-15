pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title SushiSwap Double Incentive.
 * @dev Decentralized Exchange.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract SushipswapIncentiveResolver is Helpers, Events {
	/**
	 * @dev deposit LP token to masterChef
	 * @notice deposit LP token to masterChef
	 * @param token1 token1 of LP token
	 * @param token2 token2 of LP token
	 * @param amount amount of LP token
	 * @param getId ID to retrieve amount
	 * @param setId ID stores Pool ID
	 */
	function deposit(
		address token1,
		address token2,
		uint256 amount,
		uint256 getId,
		uint256 setId,
		Metadata memory data
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		token1 = changeEthAddrToWethAddr(token1);
		token2 = changeEthAddrToWethAddr(token2);
		amount = getUint(getId, amount);
		if (
			data.poolId == uint256(-1) ||
			data.version <= 0 ||
			data.lpToken == address(0)
		) {
			data = _getPoolId(token1, token2);
		}
		setUint(setId, data.poolId);
		require(data.poolId != uint256(-1), "pool-does-not-exist");
		TokenInterface lpToken = TokenInterface(data.lpToken);
		lpToken.approve(address(masterChef), amount);
		_deposit(data, amount);
		_eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			token1,
			token2,
			data.poolId,
			data.version,
			amount
		);
	}

	/**
	 * @dev withdraw LP token from masterChef
	 * @notice withdraw LP token from masterChef
	 * @param token1 token1 of LP token
	 * @param token2 token2 of LP token
	 * @param amount amount of LP token
	 * @param getId ID to retrieve amount
	 * @param setId ID stores Pool ID
	 */
	function withdraw(
		address token1,
		address token2,
		uint256 amount,
		uint256 getId,
		uint256 setId,
		Metadata memory data
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		token1 = changeEthAddrToWethAddr(token1);
		token2 = changeEthAddrToWethAddr(token2);
		amount = getUint(getId, amount);
		if (data.poolId == uint256(-1) || data.version <= 0) {
			data = _getPoolId(token1, token2);
		}
		setUint(setId, data.poolId);
		require(data.poolId != uint256(-1), "pool-does-not-exist");
		_withdraw(data, amount);
		_eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			token1,
			token2,
			data.poolId,
			data.version,
			amount
		);
	}

	/**
	 * @dev harvest from masterChef
	 * @notice harvest from masterChef
	 * @param token1 token1 deposited of LP token
	 * @param token2 token2 deposited LP token
	 * @param setId ID stores Pool ID
	 */
	function harvest(
		address token1,
		address token2,
		uint256 setId,
		Metadata memory data
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		token1 = changeEthAddrToWethAddr(token1);
		token2 = changeEthAddrToWethAddr(token2);
		if (data.poolId == uint256(-1) || data.version <= 0) {
			data = _getPoolId(token1, token2);
		}
		setUint(setId, data.poolId);
		require(data.poolId != uint256(-1), "pool-does-not-exist");
		(, uint256 rewardsAmount) = _getUserInfo(data);
		if (data.version == 2) _harvest(data);
		else _withdraw(data, 0);
		_eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			token1,
			token2,
			data.poolId,
			data.version,
			rewardsAmount
		);
	}

	/**
	 * @dev withdraw LP token and harvest from masterChef
	 * @notice withdraw LP token and harvest from masterChef
	 * @param token1 token1 of LP token
	 * @param token2 token2 of LP token
	 * @param amount amount of LP token
	 * @param getId ID to retrieve amount
	 * @param setId ID stores Pool ID
	 */
	function withdrawAndHarvest(
		address token1,
		address token2,
		uint256 amount,
		uint256 getId,
		uint256 setId,
		Metadata memory data
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		token1 = changeEthAddrToWethAddr(token1);
		token2 = changeEthAddrToWethAddr(token2);
		amount = getUint(getId, amount);
		if (data.poolId == uint256(-1) || data.version <= 0) {
			data = _getPoolId(token1, token2);
		}
		setUint(setId, data.poolId);
		require(data.poolId != uint256(-1), "pool-does-not-exist");
		(, uint256 rewardsAmount) = _getUserInfo(data);
		_withdrawAndHarvest(data, amount);
		_eventName = "LogWithdrawAndHarvest(address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			token1,
			token2,
			data.poolId,
			data.version,
			amount,
			rewardsAmount
		);
	}

	/**
	 * @dev emergency withdraw from masterChef
	 * @notice emergency withdraw from masterChef
	 * @param token1 token1 deposited of LP token
	 * @param token2 token2 deposited LP token
	 * @param setId ID stores Pool ID
	 */
	function emergencyWithdraw(
		address token1,
		address token2,
		uint256 setId,
		Metadata memory data
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		token1 = changeEthAddrToWethAddr(token1);
		token2 = changeEthAddrToWethAddr(token2);
		if (data.poolId == uint256(-1) || data.version <= 0) {
			data = _getPoolId(token1, token2);
		}
		setUint(setId, data.poolId);
		require(data.poolId != uint256(-1), "pool-does-not-exist");
		(uint256 lpAmount, uint256 rewardsAmount) = _getUserInfo(data);
		_emergencyWithdraw(data);
		_eventName = "LogEmergencyWithdraw(address,addressuint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			token1,
			token2,
			data.poolId,
			data.version,
			lpAmount,
			rewardsAmount
		);
	}
}

contract ConnectV2SushiswapIncentive is SushipswapIncentiveResolver {
	string public constant name = "SushipswapIncentive-v1.1";
}
