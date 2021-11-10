// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;

/**
 * @title Augmented Finance v1.
 * @dev Lending & Borrowing.
 */

import { TokenInterface } from "../../../common/interfaces.sol";
import { Stores } from "../../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { AugmentedFinanceInterface } from "./interface.sol";

abstract contract AugmentedFinanceConnector is Events, Helpers {
    /**
     * @dev Deposit ETH/ERC-20 Token.
     * @notice Deposit a token to Augmented Finance for lending / collaterization
     * @param token The address of the token to deposit (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amount The amount of the token to deposit (For max: `type(uint256).max`)
     * @param getId ID to retrieve amount
     * @param setId ID stores the amount of tokens deposited
     */
    function deposit(
        address token,
        uint256 amount,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 tokenAmount = getUint(getId, amount);
        bool isEth = token == ethAddr;
        bool isMax = tokenAmount == type(uint256).max;
        address asset = isEth ? wethAddr : token;

        AugmentedFinanceInterface augmented = AugmentedFinanceInterface(
            augmentedProvider.getLendingPool()
        );
        TokenInterface tokenContract = TokenInterface(asset);

        uint256 balance = isEth
            ? address(this).balance
            : tokenContract.balanceOf(address(this));
        tokenAmount = isMax ? balance : tokenAmount;
        convertEthToWeth(isEth, tokenContract, tokenAmount);

        approve(tokenContract, address(augmented), tokenAmount);
        augmented.deposit(asset, tokenAmount, address(this), 0);

        setUint(setId, tokenAmount);

        _eventName = "LogDeposit(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, tokenAmount, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC-20 Token.
     * @notice Withdraw deposited token from Augmented Finance
     * @param token The address of the token to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amount The amount of the token to withdraw. (For max: `type(uint256).max`)
     * @param getId ID to retrieve amount
     * @param setId ID stores the amount of tokens withdrawn
     */
    function withdraw(
        address token,
        uint256 amount,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 tokenAmount = getUint(getId, amount);
        bool isEth = token == ethAddr;
        address asset = isEth ? wethAddr : token;

        AugmentedFinanceInterface augmented = AugmentedFinanceInterface(
            augmentedProvider.getLendingPool()
        );
        TokenInterface tokenContract = TokenInterface(asset);

        uint256 initialBalance = tokenContract.balanceOf(address(this));
        augmented.withdraw(asset, tokenAmount, address(this));
        uint256 finalBalance = tokenContract.balanceOf(address(this));

        tokenAmount = sub(finalBalance, initialBalance);
        convertWethToEth(isEth, tokenContract, tokenAmount);

        setUint(setId, tokenAmount);

        _eventName = "LogWithdraw(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, tokenAmount, getId, setId);
    }

    /**
     * @dev Borrow ETH/ERC-20 Token
     * @notice Borrow a token using Augmented Finance
     * @param token The address of the token to borrow (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amount The amount of the token to borrow
     * @param rateMode The type of borrow debt (For Stable: 1, Variable: 2)
     * @param getId ID to retrieve amount
     * @param setId ID stores the amount of tokens borrowed
     */
    function borrow(
        address token,
        uint256 amount,
        uint256 rateMode,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 tokenAmount = getUint(getId, amount);

        AugmentedFinanceInterface augmented = AugmentedFinanceInterface(
            augmentedProvider.getLendingPool()
        );

        bool isEth = token == ethAddr;
        address asset = isEth ? wethAddr : token;

        augmented.borrow(asset, tokenAmount, rateMode, 0, address(this));
        convertWethToEth(isEth, TokenInterface(asset), tokenAmount);

        setUint(setId, tokenAmount);

        _eventName = "LogBorrow(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, tokenAmount, rateMode, getId, setId);
    }

    /**
     * @dev Payback borrowed ETH/ERC-20 Token
     * @notice Payback debt owned
     * @param token The address of the token to payback (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amount The amount of the token to payback (For max: `type(uint256).max`)
     * @param rateMode The type of debt paying back (For Stable: 1, Variable: 2)
     * @param getId ID to retrieve amount
     * @param setId ID stores the amount of tokens paid back
     */
    function payback(
        address token,
        uint256 amount,
        uint256 rateMode,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 tokenAmount = getUint(getId, amount);
        bool isEth = token == ethAddr;
        bool isMax = tokenAmount == type(uint256).max;
        address asset = isEth ? wethAddr : token;

        AugmentedFinanceInterface augmented = AugmentedFinanceInterface(
            augmentedProvider.getLendingPool()
        );
        TokenInterface tokenContract = TokenInterface(asset);

        tokenAmount = isMax ? getPaybackBalance(asset, rateMode) : tokenAmount;
        convertEthToWeth(isEth, tokenContract, tokenAmount);

        approve(tokenContract, address(augmented), tokenAmount);
        augmented.repay(asset, tokenAmount, rateMode, address(this));

        setUint(setId, tokenAmount);

        _eventName = "LogPayback(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, tokenAmount, rateMode, getId, setId);
    }

    /**
     * @dev Enable collateral
     * @notice Enable an array of tokens as collateral
     * @param tokens Array of tokens to enable collateral
     */
    function enableCollateral(address[] calldata tokens)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 size = tokens.length;
        require(size > 0, "0-tokens-not-allowed");

        AugmentedFinanceInterface augmented = AugmentedFinanceInterface(
            augmentedProvider.getLendingPool()
        );

        for (uint256 index = 0; index < size; index += 1) {
            address token = tokens[index];

            if (getCollateralBalance(token) > 0 && !checkIsCollateral(token)) {
                augmented.setUserUseReserveAsCollateral(token, true);
            }
        }

        _eventName = "LogEnableCollateral(address[])";
        _eventParam = abi.encode(tokens);
    }
}

contract ConnectV2AugmentedFinance is AugmentedFinanceConnector {
    string public constant name = "Augmented-Finance-v1";
}
