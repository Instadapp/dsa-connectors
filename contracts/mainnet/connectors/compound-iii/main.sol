//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Compound.
 * @dev Lending & Borrowing.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { CometInterface } from "./interface.sol";

abstract contract CompoundIIIResolver is Events, Helpers {
	/**
	 * @dev Deposit base asset or collateral asset supported by the .
	 * @notice Deposit a token to Compound for lending / collaterization.
	 * @param market The address of the market from where to supply.
	 * @param token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function deposit(
		address market,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		require(
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(_token);

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, _amt);
		}

		approve(tokenContract, market, _amt);

		bool success = _supply(market, _token, _amt);
		require(success, "supply-failed");

		setUint(setId, _amt);

		_eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, _amt, getId, setId);
	}

	/**
	 * @dev Withdraw base/collateral asset or borrow base asset.
	 * @notice Withdraw base token or deposited token from Compound.
	 * @param market The address of the market from where to withdraw.
	 * @param token The address of the token to be withdrawn. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdraw(
		address market,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		require(
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(_token);

		uint256 initialBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token
		);
		bool success = _withdraw(market, token, _amt);
		require(success, "withdraw-failed");

		uint256 finalBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token
		);

		_amt = sub(finalBal, initialBal);

		convertWethToEth(isEth, tokenContract, _amt);

		setUint(setId, _amt);

		_eventName = "LogWithdraw(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, _amt, getId, setId);
	}

	/**
	 * @dev Withdraw base/collateral asset or borrow base asset.
	 * @notice Withdraw base token or deposited token from Compound.
	 * @param market The address of the market from where to withdraw.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function borrow(
		address market,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		require(market != address(0), "invalid market address");

		bool token = getBaseToken(market);
		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(_token);

		uint256 initialBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token
		);
		bool success = _withdraw(market, token, _amt);
		require(success, "borrow-failed");

		uint256 finalBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token
		);

		_amt = sub(finalBal, initialBal);

		convertWethToEth(isEth, tokenContract, _amt);

		setUint(setId, _amt);

		_eventName = "LogBorrow(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, _amt, getId, setId);
	}

	function payBack(
		address market,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(market != address(0), "invalid market address");

		address token = getBaseToken(market);
		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(_token);

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, _amt);
		}

		approve(tokenContract, market, _amt);

		bool success = _supply(market, _token, _amt);
		require(success, "supply-failed");

		setUint(setId, _amt);

		_eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, _amt, getId, setId);
	}
}

contract ConnectV3Compound is CompoundResolver {
	string public name = "Compound-v1.0";
}
