pragma solidity ^0.7.0;

/**
 * @title Element.
 * @dev Manage Element to DSA.
 */

import {TokenInterface} from "../../common/interfaces.sol";
import {Events} from "./events.sol";
import {ITranche} from "./interface.sol";

abstract contract ElementResolver is Events, Helpers {
    /**
        @dev deposit into the tranche
        @notice Deposit wrapped position tokens and receive interest and Principal ERC20 tokens.
                If interest has already been accrued by the wrapped position
                tokens held in this contract, the number of Principal tokens minted is
                reduced in order to pay for the accrued interest.
        @param tranche tranche address
        @param amount The amount of underlying to deposit
        @param destination The address to mint to
        @param getId ID to retrieve amt.
        @param setId ID stores the amount of tokens deposited.
     */
    function deposit(
        address tranche,
        uint256 amount,
        address destination,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amt = getUint(getId, amount);

        ITranche trancheVault = ITranche(tranche);

        TokenInterface token = TokenInterface(trancheVault.underlying());
        _amt = _amt == uint256(-1) ? token.balanceOf(address(this)) : _amt;
        approve(token, pool, _amt);
        trancheVault.deposit(_amt, destination);

        setUint(setId, _amt);

        _eventName = "LogDeposit(address,uint256,address)";
        _eventParam = abi.encode(tranche, _amt, destination);
    }

    /**
    @notice Burn principal tokens to withdraw underlying tokens.
    @param tranche tranche address
    @param amount The number of tokens to burn.
    @param destination The address to send the underlying too
    @param getId ID to retrieve amt.
    @param setId ID stores the amount of tokens deposited.
    @dev This method will return 1 underlying for 1 principal except when interest
         is negative, in which case the principal tokens is redeemable pro rata for
         the assets controlled by this vault.
         Also note: Redemption has the possibility of at most _SLIPPAGE_BP
         numerical error on each redemption so each principal token may occasionally redeem
         for less than 1 unit of underlying. Max loss defaults to 0.1 BP ie 0.001% loss
     */
    function withdrawPrincipal(
        address tranche,
        uint256 amount,
        address destination,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amt = getUint(getId, amount);

        ITranche trancheVault = ITranche(tranche);
        _amt = trancheVault.withdrawPrincipal(_amt, destination);

        setUint(setId, _amt);

        _eventName = "LogWithdrawPrincipal(address,uint256,address)";
        _eventParam = abi.encode(tranche, _amt, destination);
    }

    /**
    @notice Burn interest tokens to withdraw underlying tokens
    @param tranche tranche address
    @param amount The number of interest tokens to burn.
    @param destination The address to send the underlying too
    @param getId ID to retrieve amt.
    @param setId ID stores the amount of tokens deposited.
    @dev Due to slippage the redemption may receive up to _SLIPPAGE_BP less
         in output compared to the floating rate.
     */
    function withdrawInterest(
        address tranche,
        uint256 amount,
        address destination,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amt = getUint(getId, amount);

        ITranche trancheVault = ITranche(tranche);
        _amt = trancheVault.withdrawInterest(_amt, destination);

        setUint(setId, _amt);

        _eventName = "LogWithdrawInterest(address,uint256,address)";
        _eventParam = abi.encode(tranche, _amt, destination);
    }
}

contract ConnectV2Element is ElementResolver {
    string public constant name = "Element-v1";
}
