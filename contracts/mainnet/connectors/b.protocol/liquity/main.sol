pragma solidity ^0.7.6;

/**
 * @title B.Liquity.
 * @dev Lending & Borrowing.
 */
import {
    StabilityPoolLike,
    BAMMLike
} from "./interface.sol";
import { Stores } from "../../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract BLiquityResolver is Events, Helpers {
    /* Begin: Stability Pool */

    /**
     * @dev Deposit LUSD into Stability Pool
     * @notice Deposit LUSD into Stability Pool
     * @param amount Amount of LUSD to deposit into Stability Pool
     * @param getDepositId Optional storage slot to retrieve the amount of LUSD from
     * @param setDepositId Optional storage slot to store the final amount of LUSD deposited
     * @param setLqtyGainId Optional storage slot to store any LQTY gains in
    */
    function deposit(
        uint amount,
        uint getDepositId,
        uint setDepositId,
        uint setLqtyGainId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        amount = getUint(getDepositId, amount);

        amount = amount == uint(-1) ? lusdToken.balanceOf(address(this)) : amount;

        uint lqtyBalanceBefore = lqtyToken.balanceOf(address(this));
        
        lusdToken.approve(address(BAMM), amount);
        BAMM.deposit(amount);
        
        uint lqtyBalanceAfter = lqtyToken.balanceOf(address(this));
        uint lqtyGain = sub(lqtyBalanceAfter, lqtyBalanceBefore);

        setUint(setDepositId, amount);
        setUint(setLqtyGainId, lqtyGain);

        _eventName = "LogStabilityDeposit(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), amount,lqtyGain, getDepositId, setDepositId, setLqtyGainId);
    }

    /**
     * @dev Withdraw user deposited LUSD from Stability Pool
     * @notice Withdraw LUSD from Stability Pool
     * @param numShares amount of shares to withdraw from the BAMM
     * @param getWithdrawId Optional storage slot to retrieve the amount of LUSD to withdraw from
     * @param setWithdrawId Optional storage slot to store the withdrawn LUSD
     * @param setLqtyGainId Optional storage slot to store any LQTY gains in
    */
    function withdraw(
        uint numShares,
        uint getWithdrawId,
        uint setWithdrawId,
        uint setLqtyGainId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        numShares = getUint(getWithdrawId, numShares);

        numShares = numShares == uint(-1) ? BAMM.balanceOf(address(this)) : numShares;

        uint lqtyBalanceBefore = lqtyToken.balanceOf(address(this));
        
        BAMM.withdraw(numShares);
        
        uint lqtyBalanceAfter = lqtyToken.balanceOf(address(this));
        uint lqtyGain = sub(lqtyBalanceAfter, lqtyBalanceBefore);

        setUint(setWithdrawId, numShares);
        setUint(setLqtyGainId, lqtyGain);

        _eventName = "LogStabilityWithdraw(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(this), numShares, lqtyGain, getWithdrawId, setWithdrawId, setLqtyGainId);
    }
}

contract ConnectV2BLiquity is BLiquityResolver {
    string public name = "B.Liquity-v1";
}