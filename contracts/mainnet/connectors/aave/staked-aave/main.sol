pragma solidity ^0.7.0;


/**
 * @title stkAave.
 * @dev Staked Aave.
 */

import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract AaveResolver is Helpers, Events {

    /**
     * @dev Claim Accrued AAVE.
     * @notice Claim Accrued AAVE Token rewards.
     * @param amount The amount of rewards to claim. uint(-1) for max.
     * @param getId ID to retrieve amount.
     * @param setId ID stores the amount of tokens claimed.
    */
    function claim(
        uint256 amount,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amount);

        uint intialBal = aave.balanceOf(address(this));
        stkAave.claimRewards(address(this), _amt);
        uint finalBal = aave.balanceOf(address(this));
        _amt = sub(finalBal, intialBal);

        setUint(setId, _amt);

        _eventName = "LogClaim(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }

    /**
     * @dev Stake AAVE Token
     * @notice Stake AAVE Token in Aave security module
     * @param amount The amount of AAVE to stake. uint(-1) for max.
     * @param getId ID to retrieve amount.
     * @param setId ID stores the amount of tokens staked.
    */
    function stake(
        uint256 amount,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amount);

        _amt = _amt == uint(-1) ? aave.balanceOf(address(this)) : _amt;
        stkAave.stake(address(this), _amt);

        setUint(setId, _amt);

        _eventName = "LogStake(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }

    /**
     * @dev Initiate cooldown to unstake
     * @notice Initiate cooldown to unstake from Aave security module
    */
    function cooldown() external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(stkAave.balanceOf(address(this)) > 0, "no-staking");

        stkAave.cooldown();

        _eventName = "LogCooldown()";
    }

    /**
     * @dev Redeem tokens from Staked AAVE
     * @notice Redeem AAVE tokens from Staked AAVE after cooldown period is over
     * @param amount The amount of AAVE to redeem. uint(-1) for max.
     * @param getId ID to retrieve amount.
     * @param setId ID stores the amount of tokens redeemed.
    */
    function redeem(
        uint256 amount,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amount);

        uint intialBal = aave.balanceOf(address(this));
        stkAave.redeem(address(this), _amt);
        uint finalBal = aave.balanceOf(address(this));
        _amt = sub(finalBal, intialBal);

        setUint(setId, _amt);

        _eventName = "LogRedeem(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }

    /**
     * @dev Delegate AAVE or stkAAVE
     * @notice Delegate AAVE or stkAAVE
     * @param delegatee The address of the delegatee
     * @param delegateAave Whether to delegate Aave balance
     * @param delegateStkAave Whether to delegate Staked Aave balance
     * @param aaveDelegationType Aave delegation type. Voting power - 0, Proposition power - 1, Both - 2
     * @param stkAaveDelegationType Staked Aave delegation type. Values similar to aaveDelegationType
    */
    function delegate(
        address delegatee,
        bool delegateAave,
        bool delegateStkAave,
        uint8 aaveDelegationType,
        uint8 stkAaveDelegationType
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(delegateAave || delegateStkAave, "invalid-delegate");
        require(delegatee != address(0), "invalid-delegatee");

        if (delegateAave) {
            _delegateAave(delegatee, Helpers.DelegationType(aaveDelegationType));
        }

        if (delegateStkAave) {
            _delegateStakedAave(delegatee, Helpers.DelegationType(stkAaveDelegationType));
        }

        _eventName = "LogDelegate(address,bool,bool,uint8,uint8)";
        _eventParam = abi.encode(delegatee, delegateAave, delegateStkAave, aaveDelegationType, stkAaveDelegationType);
    }
}


contract ConnectV2AaveStake is AaveResolver {
    string public constant name = "Aave-Stake-v1";
}
