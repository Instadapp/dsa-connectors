//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Sturdy
 * @dev Lending & Borrowing.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { SturdyLendingPoolInterface, SturdyCollateralAdapterInterface, SturdyVaultInterface } from "./interface.sol";
import "hardhat/console.sol";

abstract contract SturdyResolver is Events, Helpers {
	/**
	 * @dev Deposit Stable Coins
	 * @notice Deposit a token to Sturdy for farming.
	 * @param token The address of the token to deposit.
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function deposit(
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		SturdyLendingPoolInterface sturdy = SturdyLendingPoolInterface(sturdyAddressesProvider.getLendingPool());

		TokenInterface tokenContract = TokenInterface(token);

		_amt = _amt == uint256(-1)
			? tokenContract.balanceOf(address(this))
			: _amt;

		approve(tokenContract, address(sturdy), _amt);

		sturdy.deposit(token, _amt, address(this), referralCode);

		setUint(setId, _amt);

		_eventName = "LogDeposit(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);
	}

	/**
	 * @dev Withdraw ETH/ERC20_Token.
	 * @notice Withdraw deposited token from Sturdy v2
	 * @param token The address of the token to withdraw.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdraw(
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		SturdyLendingPoolInterface sturdy = SturdyLendingPoolInterface(sturdyAddressesProvider.getLendingPool());

		TokenInterface tokenContract = TokenInterface(token);

		sturdy.withdraw(token, _amt, address(this));

		setUint(setId, _amt);

		_eventName = "LogWithdraw(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);
	}

	/**
	 * @dev Borrow ETH/ERC20_Token.
	 * @notice Borrow a token using Sturdy v2
	 * @param token The address of the token to borrow.
	 * @param amt The amount of the token to borrow.
	 * @param rateMode The type of borrow debt. (For Stable: 1, Variable: 2)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens borrowed.
	 */
	function borrow(
		address token,
		uint256 amt,
		uint256 rateMode,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		SturdyLendingPoolInterface sturdy = SturdyLendingPoolInterface(sturdyAddressesProvider.getLendingPool());

		sturdy.borrow(token, _amt, rateMode, referralCode, address(this));

		setUint(setId, _amt);

		_eventName = "LogBorrow(address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, rateMode, getId, setId);
	}

	/**
	 * @dev Repay borrowed ETH/ERC20_Token.
	 * @notice Repay debt owed.
	 * @param token The address of the token to payback.
	 * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
	 * @param rateMode The type of debt paying back. (For Stable: 1, Variable: 2)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens paid back.
	 */
	function repay(
		address token,
		uint256 amt,
		uint256 rateMode,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		SturdyLendingPoolInterface sturdy = SturdyLendingPoolInterface(sturdyAddressesProvider.getLendingPool());

		TokenInterface tokenContract = TokenInterface(token);

		if (_amt == uint256(-1)) {
			uint256 _amtDSA = tokenContract.balanceOf(address(this));
			uint256 _amtDebt = getRepayBalance(token, rateMode);
			_amt = _amtDSA <= _amtDebt ? _amtDSA : _amtDebt;
		}

		approve(tokenContract, address(sturdy), _amt);

		sturdy.repay(token, _amt, rateMode, address(this));

		setUint(setId, _amt);

		_eventName = "LogRepay(address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, rateMode, getId, setId);
	}

	/**
	 * @dev Repay borrowed ETH/ERC20_Token on behalf of a user.
	 * @notice Repay debt owed on behalf os a user.
	 * @param token The address of the token to payback.
	 * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
	 * @param rateMode The type of debt paying back. (For Stable: 1, Variable: 2)
	 * @param onBehalfOf Address of user who's debt to repay.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens paid back.
	 */
	function repayOnBehalfOf(
		address token,
		uint256 amt,
		uint256 rateMode,
		address onBehalfOf,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		SturdyLendingPoolInterface sturdy = SturdyLendingPoolInterface(sturdyAddressesProvider.getLendingPool());

		TokenInterface tokenContract = TokenInterface(token);

		if (_amt == uint256(-1)) {
			uint256 _amtDSA = tokenContract.balanceOf(address(this));
			uint256 _amtDebt = getOnBehalfOfRepayBalance(
				token,
				rateMode,
				onBehalfOf
			);
			_amt = _amtDSA <= _amtDebt ? _amtDSA : _amtDebt;
		}

		approve(tokenContract, address(sturdy), _amt);

		sturdy.repay(token, _amt, rateMode, onBehalfOf);

		setUint(setId, _amt);

		_eventName = "LogRepayOnBehalfOf(address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			token,
			_amt,
			rateMode,
			onBehalfOf,
			getId,
			setId
		);
	}

	/**
	 * @dev Deposit Collateral
	 * @notice Deposit a token to Sturdy for lending.
	 * @param token The address of the token to deposit.
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function depositCollateral(
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		SturdyCollateralAdapterInterface sturdyCollateralAdapter = SturdyCollateralAdapterInterface(sturdyAddressesProvider.getAddress('COLLATERAL_ADAPTER'));

		address vault = token == stEthAddr ? sturdyLidoVault : sturdyCollateralAdapter.getAcceptableVault(token);
		require(vault != address(0), "Collateral is not supported");

		SturdyVaultInterface sturdyVault = SturdyVaultInterface(vault);

		TokenInterface tokenContract = TokenInterface(token);
		_amt = _amt == uint256(-1)
		    ? tokenContract.balanceOf(address(this))
		    : _amt;

		approve(tokenContract, address(sturdyVault), _amt);

		sturdyVault.depositCollateralFrom(token, _amt, address(this));

		setUint(setId, _amt);

		_eventName = "LogDepositCollateral(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);
	}

	/**
	 * @dev Withdraw ETH/ERC20_Token.
	 * @notice Withdraw deposited collateral from Sturdy
	 * @param token The address of the token to withdraw.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdrawCollateral(
		address token,
		uint256 amt,
        uint256 slippage,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		SturdyCollateralAdapterInterface sturdyCollateralAdapter = SturdyCollateralAdapterInterface(sturdyAddressesProvider.getAddress('COLLATERAL_ADAPTER'));

		address vault = token == stEthAddr ? sturdyLidoVault : sturdyCollateralAdapter.getAcceptableVault(token);
		require(vault != address(0), "Collateral is not supported");

		SturdyVaultInterface sturdyVault = SturdyVaultInterface(vault);

		sturdyVault.withdrawCollateral(token, _amt, slippage, address(this));

		setUint(setId, _amt);

		_eventName = "LogWithdrawCollateral(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);
	}

}

contract ConnectV2Sturdy is SturdyResolver {
	string public constant name = "Sturdy-v1";
}
