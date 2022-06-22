//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Aave v3.
 * @dev Lending & Borrowing.
 */

import { TokenInterface } from "../../../common/interfaces.sol";
import { Stores } from "../../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { AaveInterface, DTokenInterface } from "./interface.sol";

abstract contract AaveResolver is Events, Helpers {
	/**
	 * @dev Deposit ETH/ERC20_Token.
	 * @notice Deposit a token to Aave v3 for lending / collaterization.
	 * @param token The address of the token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
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

		AaveInterface aave = AaveInterface(aaveProvider.getPool());

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(_token);

		if (isEth) {
			_amt = _amt == uint256(-1) ? address(this).balance : _amt;
			convertEthToWeth(isEth, tokenContract, _amt);
		} else {
			_amt = _amt == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: _amt;
		}

		approve(tokenContract, address(aave), _amt);

		aave.supply(_token, _amt, address(this), referralCode);

		if (!getIsColl(_token)) {
			aave.setUserUseReserveAsCollateral(_token, true);
		}

		setUint(setId, _amt);

		_eventName = "LogDeposit(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);
	}

	/**
	 * @dev Deposit ETH/ERC20_Token without collateral
	 * @notice Deposit a token to Aave v3 without enabling it as collateral.
	 * @param token The address of the token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function depositWithoutCollateral(
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

		AaveInterface aave = AaveInterface(aaveProvider.getPool());

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(_token);

		if (isEth) {
			_amt = _amt == uint256(-1) ? address(this).balance : _amt;
			convertEthToWeth(isEth, tokenContract, _amt);
		} else {
			_amt = _amt == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: _amt;
		}

		approve(tokenContract, address(aave), _amt);

		aave.supply(_token, _amt, address(this), referralCode);

		if (getCollateralBalance(_token) > 0 && getIsColl(_token)) {
			aave.setUserUseReserveAsCollateral(_token, false);
		}

		setUint(setId, _amt);

		_eventName = "LogDepositWithoutCollateral(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);
	}

	/**
	 * @dev Withdraw ETH/ERC20_Token.
	 * @notice Withdraw deposited token from Aave v3
	 * @param token The address of the token to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
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

		AaveInterface aave = AaveInterface(aaveProvider.getPool());
		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(_token);

		uint256 initialBal = tokenContract.balanceOf(address(this));
		aave.withdraw(_token, _amt, address(this));
		uint256 finalBal = tokenContract.balanceOf(address(this));

		_amt = sub(finalBal, initialBal);

		convertWethToEth(isEth, tokenContract, _amt);

		setUint(setId, _amt);

		_eventName = "LogWithdraw(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);
	}

	/**
	 * @dev Borrow ETH/ERC20_Token.
	 * @notice Borrow a token using Aave v3
	 * @param token The address of the token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to borrow.
	 * @param rateMode The type of debt. (For Stable: 1, Variable: 2)
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

		AaveInterface aave = AaveInterface(aaveProvider.getPool());

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		aave.borrow(_token, _amt, rateMode, referralCode, address(this));
		convertWethToEth(isEth, TokenInterface(_token), _amt);

		setUint(setId, _amt);

		_eventName = "LogBorrow(address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, rateMode, getId, setId);
	}

	/**
	 * @dev Borrow ETH/ERC20_Token on behalf of a user.
	 * @notice Borrow a token using Aave v3 on behalf of a user
	 * @param token The address of the token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to borrow.
	 * @param rateMode The type of debt. (For Stable: 1, Variable: 2)
	 * @param onBehalfOf The user who will incur the debt
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens borrowed.
	 */
	function borrowOnBehalfOf(
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

		AaveInterface aave = AaveInterface(aaveProvider.getPool());

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		aave.borrow(_token, _amt, rateMode, referralCode, onBehalfOf);
		convertWethToEth(isEth, TokenInterface(_token), _amt);

		setUint(setId, _amt);

		_eventName = "LogBorrowOnBehalfOf(address,uint256,uint256,address,uint256,uint256)";
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
	 * @dev Payback borrowed ETH/ERC20_Token.
	 * @notice Payback debt owed.
	 * @param token The address of the token to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
	 * @param rateMode The type of debt paying back. (For Stable: 1, Variable: 2)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens paid back.
	 */
	function payback(
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

		AaveInterface aave = AaveInterface(aaveProvider.getPool());

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(_token);

		_amt = _amt == uint256(-1) ? getPaybackBalance(_token, rateMode) : _amt;

		if (isEth) convertEthToWeth(isEth, tokenContract, _amt);

		approve(tokenContract, address(aave), _amt);

		aave.repay(_token, _amt, rateMode, address(this));

		setUint(setId, _amt);

		_eventName = "LogPayback(address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, rateMode, getId, setId);
	}

	/**
	 * @dev Payback borrowed ETH/ERC20_Token using aTokens.
	 * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the equivalent debt tokens.
	 * @param token The address of the token to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
	 * @param rateMode The type of debt paying back. (For Stable: 1, Variable: 2)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens paid back.
	 */
	function paybackWithATokens(
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

		AaveInterface aave = AaveInterface(aaveProvider.getPool());

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(_token);

		_amt = _amt == uint256(-1) ? getPaybackBalance(_token, rateMode) : _amt;

		if (isEth) convertEthToWeth(isEth, tokenContract, _amt);

		approve(tokenContract, address(aave), _amt);

		aave.repayWithATokens(_token, _amt, rateMode);

		setUint(setId, _amt);

		_eventName = "LogPayback(address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, rateMode, getId, setId);
	}

	/**
	 * @dev Payback borrowed ETH/ERC20_Token on behalf of a user.
	 * @notice Payback debt owed on behalf os a user.
	 * @param token The address of the token to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
	 * @param rateMode The type of debt paying back. (For Stable: 1, Variable: 2)
	 * @param onBehalfOf Address of user who's debt to repay.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens paid back.
	 */
	function paybackOnBehalfOf(
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

		AaveInterface aave = AaveInterface(aaveProvider.getPool());

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(_token);

		_amt = _amt == uint256(-1)
			? getOnBehalfOfPaybackBalance(_token, rateMode, onBehalfOf)
			: _amt;

		if (isEth) convertEthToWeth(isEth, tokenContract, _amt);

		approve(tokenContract, address(aave), _amt);

		aave.repay(_token, _amt, rateMode, onBehalfOf);

		setUint(setId, _amt);

		_eventName = "LogPaybackOnBehalfOf(address,uint256,uint256,address,uint256,uint256)";
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
	 * @dev Enable collateral
	 * @notice Enable an array of tokens as collateral
	 * @param tokens Array of tokens to enable collateral
	 */
	function enableCollateral(address[] calldata tokens)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _length = tokens.length;
		require(_length > 0, "0-tokens-not-allowed");

		AaveInterface aave = AaveInterface(aaveProvider.getPool());

		for (uint256 i = 0; i < _length; i++) {
			bool isEth = tokens[i] == ethAddr;
			address _token = isEth ? wethAddr : tokens[i];

			if (getCollateralBalance(_token) > 0 && !getIsColl(_token)) {
				aave.setUserUseReserveAsCollateral(_token, true);
			}
		}

		_eventName = "LogEnableCollateral(address[])";
		_eventParam = abi.encode(tokens);
	}

	/**
	 * @dev Disable collateral
	 * @notice Disable an array of tokens as collateral
	 * @param tokens Array of tokens to disable as collateral
	 */
	function disableCollateral(address[] calldata tokens)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _length = tokens.length;
		require(_length > 0, "0-tokens-not-allowed");

		AaveInterface aave = AaveInterface(aaveProvider.getPool());

		for (uint256 i = 0; i < _length; i++) {
			bool isEth = tokens[i] == ethAddr;
			address _token = isEth ? wethAddr : tokens[i];

			if (getCollateralBalance(_token) > 0 && getIsColl(_token)) {
				aave.setUserUseReserveAsCollateral(_token, false);
			}
		}

		_eventName = "LogDisableCollateral(address[])";
		_eventParam = abi.encode(tokens);
	}

	/**
	 * @dev Swap borrow rate mode
	 * @notice Swaps user borrow rate mode between variable and stable
	 * @param token The address of the token to swap borrow rate.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param rateMode Current borrow rate (Stable = 1, Variable = 2)
	 */
	function swapBorrowRateMode(address token, uint256 rateMode)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		AaveInterface aave = AaveInterface(aaveProvider.getPool());

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		if (getPaybackBalance(_token, rateMode) > 0) {
			aave.swapBorrowRateMode(_token, rateMode);
		}

		_eventName = "LogSwapRateMode(address,uint256)";
		_eventParam = abi.encode(token, rateMode);
	}

	/**
	 * @dev Set user e-mode
	 * @notice Updates the user's e-mode category
	 * @param categoryId The category Id of the e-mode user want to set
	 */
	function setUserEMode(uint8 categoryId)
		external
		returns (string memory _eventName, bytes memory _eventParam)
	{
		AaveInterface aave = AaveInterface(aaveProvider.getPool());

		aave.setUserEMode(categoryId);

		_eventName = "LogSetUserEMode(uint8)";
		_eventParam = abi.encode(categoryId);
	}

	/**
	 * @dev Approve Delegation
	 * @notice Gives approval to delegate debt tokens
	 * @param token The address of token
	 * @param amount The amount
	 * @param rateMode The type of debt
	 * @param delegateTo The address to whom the user is delegating
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens delegated.
	 */
	function delegateBorrow(
		address token,
		uint256 amount,
		uint256 rateMode,
		address delegateTo,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(rateMode == 1 || rateMode == 2, "Invalid debt type");
		uint256 _amt = getUint(getId, amount);

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		address _dToken = getDTokenAddr(_token, rateMode);
		DTokenInterface(_dToken).approveDelegation(delegateTo, _amt);

		setUint(setId, _amt);

		_eventName = "LogDelegateBorrow(address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			token,
			_amt,
			rateMode,
			delegateTo,
			getId,
			setId
		);
	}
}

contract ConnectV2AaveV3Optimism is AaveResolver {
	string public constant name = "AaveV3-v1.2";
}
