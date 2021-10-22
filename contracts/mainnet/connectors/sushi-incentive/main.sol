pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title SushiSwap Double Incentive.
 * @dev Decentralized Exchange.
 */

import {TokenInterface} from "../../common/interfaces.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

abstract contract SushipswapIncentiveResolver is Helpers, Events {
    /**
     * @dev deposit LP token to masterChef
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
        uint256 setId
    ) external {
        amount = getUint(getId, amount);
        (uint256 _pid, uint256 _version, address lpTokenAddr) = _getPoolId(
            token1,
            token2
        );
        setUint(setId, _pid);
        require(_pid != uint256(-1), "pool-does-not-exist");
        TokenInterface lpToken = TokenInterface(lpTokenAddr);
        lpToken.approve(address(masterChef), amount);
        _deposit(_pid, amount, _version);
        emit LogDeposit(address(this), _pid, _version, amount);
    }

    /**
     * @dev withdraw LP token from masterChef
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
        uint256 setId
    ) external {
        amount = getUint(getId, amount);
        (uint256 _pid, uint256 _version, ) = _getPoolId(token1, token2);
        setUint(setId, _pid);
        require(_pid != uint256(-1), "pool-does-not-exist");
        _withdraw(_pid, amount, _version);
        emit LogWithdraw(address(this), _pid, _version, amount);
    }

    /**
     * @dev harvest from masterChef
     * @param token1 token1 deposited of LP token
     * @param token2 token2 deposited LP token
     * @param setId ID stores Pool ID
     */
    function harvest(
        address token1,
        address token2,
        uint256 setId
    ) external {
        (uint256 _pid, uint256 _version, ) = _getPoolId(token1, token2);
        setUint(setId, _pid);
        require(_pid != uint256(-1), "pool-does-not-exist");
        (, uint256 rewardsAmount) = _getUserInfo(_pid, _version);
        if (_version == 2) _harvest(_pid);
        else _withdraw(_pid, 0, _version);
        emit LogHarvest(address(this), _pid, _version, rewardsAmount);
    }

    /**
     * @dev withdraw LP token and harvest from masterChef
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
        uint256 setId
    ) external {
        amount = getUint(getId, amount);
        (uint256 _pid, uint256 _version, ) = _getPoolId(token1, token2);
        setUint(setId, _pid);
        require(_pid != uint256(-1), "pool-does-not-exist");
        (, uint256 rewardsAmount) = _getUserInfo(_pid, _version);
        _withdrawAndHarvest(_pid, amount, _version);
        emit LogWithdrawAndHarvest(
            address(this),
            _pid,
            _version,
            amount,
            rewardsAmount
        );
    }

    /**
     * @dev emergency withdraw from masterChef
     * @param token1 token1 deposited of LP token
     * @param token2 token2 deposited LP token
     * @param setId ID stores Pool ID
     */
    function emergencyWithdraw(
        address token1,
        address token2,
        uint256 setId
    ) external {
        (uint256 _pid, uint256 _version, ) = _getPoolId(token1, token2);
        setUint(setId, _pid);
        require(_pid != uint256(-1), "pool-does-not-exist");
        (uint256 lpAmount, uint256 rewardsAmount) = _getUserInfo(
            _pid,
            _version
        );
        _emergencyWithdraw(_pid, _version);
        emit LogEmergencyWithdraw(
            address(this),
            _pid,
            _version,
            lpAmount,
            rewardsAmount
        );
    }
}

contract ConnectV2SushiswapIncentive is SushipswapIncentiveResolver {
    string public constant name = "SushipswapIncentive-v1.1";
}
