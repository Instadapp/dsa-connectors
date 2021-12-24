// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import "./interface.sol";

contract Helpers is DSMath, Basic {
    IMasterChefV2 immutable masterChefV2 =
        IMasterChefV2(0xEF0881eC094552b2e128Cf945EF17a6752B4Ec5d);
    IMasterChef immutable masterChef =
        IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    ISushiSwapFactory immutable factory =
        ISushiSwapFactory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);

    function _deposit(uint256 _pid, uint256 _amount, uint256 _version) internal {
        if(_version == 2)
            masterChefV2.deposit(_pid, _amount, address(this));
        else
            masterChef.deposit(_pid, _amount);
    }

    function _withdraw(uint256 _pid, uint256 _amount, uint256 _version) internal {
        if(_version == 2)
            masterChefV2.withdraw(_pid, _amount, address(this));
        else
            masterChef.withdraw(_pid, _amount);
    }

    function _harvest(uint256 _pid) internal {
        masterChefV2.harvest(_pid, address(this));
    }

    function _withdrawAndHarvest(uint256 _pid, uint256 _amount, uint256 _version) internal {
        if(_version == 2)
            masterChefV2.withdrawAndHarvest(_pid, _amount, address(this));
        else _withdraw(_pid, _amount, _version);
    }

    function _emergencyWithdraw(uint256 _pid, uint256 _version) internal {
        if(_version == 2)
            masterChefV2.emergencyWithdraw(_pid, address(this));
        else 
            masterChef.emergencyWithdraw(_pid, address(this));
    }

    function _getPoolId(address tokenA, address tokenB)
        internal
        view
        returns (uint256 poolId, uint256 version, address lpToken)
    {
        address pair = factory.getPair(tokenA, tokenB);
        uint256 length = masterChefV2.poolLength();
        version = 2;
        poolId = uint256(-1);

        for (uint256 i = 0; i < length; i++) {
            lpToken = masterChefV2.lpToken(i);
            if (pair == lpToken) {
                poolId = i;
                break;
            }
        }

        uint256 lengthV1 = masterChef.poolLength();
        for (uint256 i = 0; i < lengthV1; i++) {
            (lpToken, , , ) = masterChef.poolInfo(i);
            if (pair == lpToken) {
                poolId = i;
                version = 1;
                break;
            }
        }
    }

    function _getUserInfo(uint256 _pid, uint256 _version)
        internal
        view
        returns (uint256 lpAmount, uint256 rewardsAmount)
    {
        if(_version == 2)
            (lpAmount, rewardsAmount) = masterChefV2.userInfo(_pid, address(this));
        else 
            (lpAmount, rewardsAmount) = masterChef.userInfo(_pid, address(this));
    }
}
