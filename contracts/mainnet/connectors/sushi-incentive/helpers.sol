// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import "./interface.sol";

contract Helpers is DSMath, Basic {
	IMasterChefV2 immutable masterChefV2 =
		IMasterChefV2(0xEF0881eC094552b2e128Cf945EF17a6752B4Ec5d);
	IMasterChef immutable masterChef =
		IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
	ISushiSwapFactory immutable factory =
		ISushiSwapFactory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);

	struct Metadata {
		uint256 poolId;
		uint256 version;
		address lpToken;
	}

	function _deposit(Metadata memory data, uint256 _amount) internal {
		if (data.version == 2)
			masterChefV2.deposit(data.poolId, _amount, address(this));
		else masterChef.deposit(data.poolId, _amount);
	}

	function _withdraw(Metadata memory data, uint256 _amount) internal {
		if (data.version == 2)
			masterChefV2.withdraw(data.poolId, _amount, address(this));
		else masterChef.withdraw(data.poolId, _amount);
	}

	function _harvest(Metadata memory data) internal {
		masterChefV2.harvest(data.poolId, address(this));
	}

	function _withdrawAndHarvest(Metadata memory data, uint256 _amount)
		internal
	{
		if (data.version == 2)
			masterChefV2.withdrawAndHarvest(
				data.poolId,
				_amount,
				address(this)
			);
		else _withdraw(data, _amount);
	}

	function _emergencyWithdraw(Metadata memory data) internal {
		if (data.version == 2)
			masterChefV2.emergencyWithdraw(data.poolId, address(this));
		else masterChef.emergencyWithdraw(data.poolId, address(this));
	}

	function _getPoolId(address tokenA, address tokenB)
		internal
		view
		returns (Metadata memory data)
	{
		address pair = factory.getPair(tokenA, tokenB);
		uint256 length = masterChefV2.poolLength();
		data.version = 2;
		data.poolId = uint256(-1);

		for (uint256 i = 0; i < length; i++) {
			data.lpToken = masterChefV2.lpToken(i);
			if (pair == data.lpToken) {
				data.poolId = i;
				break;
			}
		}

		uint256 lengthV1 = masterChef.poolLength();
		for (uint256 i = 0; i < lengthV1; i++) {
			(data.lpToken, , , ) = masterChef.poolInfo(i);
			if (pair == data.lpToken) {
				data.poolId = i;
				data.version = 1;
				break;
			}
		}
	}

	function _getUserInfo(Metadata memory data)
		internal
		view
		returns (uint256 lpAmount, uint256 rewardsAmount)
	{
		if (data.version == 2)
			(lpAmount, rewardsAmount) = masterChefV2.userInfo(
				data.poolId,
				address(this)
			);
		else
			(lpAmount, rewardsAmount) = masterChef.userInfo(
				data.poolId,
				address(this)
			);
	}
}
