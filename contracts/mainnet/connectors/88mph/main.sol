pragma solidity ^0.7.0;

/**
 * @title 88mph.
 * @dev Manage 88mph to DSA.
 */

import {TokenInterface} from "../../common/interfaces.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";
import {IDInterest} from "./interface.sol";

abstract contract MPHResolver is Events, Helpers {
    /**
        @notice Creates a single deposit for the caller
        @dev Creates a single deposit for the caller
        @param pool pool address
        @param amount The amount of underlying to deposit
        @param maturationTimestamp The Unix timestamp at and after which the deposit will be able to be withdrawn. In seconds.
        @param getId ID to retrieve amt.
        @param setId ID stores the amount of tokens deposited.
     */
    function deposit(
        address pool,
        uint256 amount,
        uint256 maturationTimestamp,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getId, amount);

        IDInterest pool = IDInterest(tranche);

        TokenInterface token = TokenInterface(pool.underlying());
        _amt = _amt == uint256(-1) ? token.balanceOf(address(this)) : _amt;
        approve(token, pool, _amt);
        pool.deposit(_amt, destination);
        setUint(setId, _amt);

        _eventName = "LogDeposit(address,uint256,uint256)";
        _eventParam = abi.encode(poolId, _amt, maturationTimestamp);
    }

    /**
        @notice Withdraws a single deposit for the caller
        @dev The caller must own the deposit NFT with ID depositID.
        @param pool pool address
        @param depositID The index of the deposit to be withdrawn in the deposits array plus 1
        @param fundingID The index of the funding object that funded the deposit's debt in the fundingList array plus 1
     */
    function withdraw(
        address pool,
        uint256 depositID,
        uint256 fundingID
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        IDInterest pool = IDInterest(tranche);
        pool.withdraw(depositID, fundingID);

        _eventName = "LogWithdraw(address,uint256,uint256)";
        _eventParam = abi.encode(pool, depositID, fundingID);
    }

    /**
        @notice Withdraws a single deposit for the caller, before the maturation timestamp
        @dev The caller must own the deposit NFT with ID depositID.
        @param pool pool address
        @param depositID The index of the deposit to be withdrawn in the deposits array plus 1
        @param fundingID The index of the funding object that funded the deposit's debt in the fundingList array plus 1
     */
    function earlyWithdraw(
        address pool,
        uint256 depositID,
        uint256 fundingID
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        IDInterest pool = IDInterest(tranche);
        pool.earlyWithdraw(depositID, fundingID);

        _eventName = "LogEarlyWithdraw(address,uint256,uint256)";
        _eventParam = abi.encode(pool, depositID, fundingID);
    }

    /**
        @notice Increment the highest vest index
        @dev increment the highest vest index.
        @param to
        @param amount
        @param vestPeriodInSeconds
     */
    function vest(
        address to,
        uint256 amount,
        uint256 vestPeriodInSeconds
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 vestIdx = vesting.vest(to, amount, vestPeriodInSeconds);
        _eventName = "LogVest(uint256)";
        _eventParam = abi.encode(vestIdx);
    }

    /**
        @notice withdraw vested MPH
        @dev withdraw vested MPH.
        @param account account to withdraw
        @param vestIdx
     */
    function withdrawVested(address account, uint256 vestIdx)
        external
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 withdrawnAmount = vesting.withdrawVested(account, vestIdx);
        _eventName = "LogWithdrawReward(uint256,uint256)";
        _eventParam = abi.encode(vestIdx, withdrawnAmount);
    }
}

contract ConnectV288MPH is MPHResolver {
    string public constant name = "88MPH-v1";
}
