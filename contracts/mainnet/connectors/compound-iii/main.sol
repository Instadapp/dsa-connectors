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
	 * @dev Deposit base asset or collateral asset supported by the market.
	 * @notice Deposit a token to Compound for lending / collaterization.
	 * @param market The address of the market where to supply.
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

		bool success = _supply(market, _token, 0x00, 0x00, _amt);
		require(success, "supply-failed");

		setUint(setId, _amt);

		_eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, _amt, getId, setId);
	}

	/**
	 * @dev Deposit base asset or collateral asset supported by the market on behalf of 'to'.
	 * @notice Deposit a token to Compound for lending / collaterization on behalf of 'to'.
	 * @param market The address of the market where to supply.
	 * @param token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE).
     * @param to The address on behalf of which the supply is made.
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function depositOnBehalf(
		address market,
		address token,
		address to,
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

		bool success = _supply(market, _token, 0x00, to, _amt);
		require(success, "supply-failed");

		setUint(setId, _amt);

		_eventName = "LogDepositOnBehalf(address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, to, _amt, getId, setId);
	}

	/**
	 * @dev Deposit base asset or collateral asset supported by the market from 'from' address and update the position of 'to'.
	 * @notice Deposit a token to Compound for lending / collaterization from a address and update the position of 'to'.
	 * @param market The address of the market from where to supply.
	 * @param token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param from The address from where amount is to be supplied.
     * @param to The address on account of which the supply is made or whose positions are updated.
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function depositFrom(
		address market,
		address token,
		address from,
        address to,
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

		bool success = _supply(market, _token, from, to, _amt);
		require(success, "supply-failed");

		setUint(setId, _amt);

		_eventName = "LogDepositFrom(address,address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, from, to, _amt, getId, setId);
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
		bool success = _withdraw(market, token, 0x00, 0x00, _amt);
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
	 * @dev Withdraw base/collateral asset or borrow base asset and transfer to 'to'.
	 * @notice Withdraw base token or deposited token from Compound on behalf of an address and transfer to 'to'.
	 * @param market The address of the market from where to withdraw.
	 * @param token The address of the token to be withdrawn. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param to The address to which the borrowed assets are to be transferred.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdrawOnbehalf(
		address market,
		address token,
        address to,
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
		bool success = _withdraw(market, token, 0x00, to, _amt);
		require(success, "withdraw-failed");

		uint256 finalBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token
		);

		_amt = sub(finalBal, initialBal);

		convertWethToEth(isEth, tokenContract, _amt);

		setUint(setId, _amt);

		_eventName = "LogWithdrawOnBehalf(address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, to, _amt, getId, setId);
	}

	/**
	 * @dev Withdraw base/collateral asset or borrow base asset from an account and transfer to 'to'.
	 * @notice Withdraw base token or deposited token from Compound from an address and transfer to 'to'.
	 * @param market The address of the market from where to withdraw.
	 * @param token The address of the token to be withdrawn. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param from The address from where asset is to be withdrawed.
     * @param to The address to which the borrowed assets are to be transferred.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdrawFrom(
		address market,
		address token,
        address from,
        address to,
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
		bool success = _withdraw(market, token, from, to, _amt);
		require(success, "withdraw-failed");

		uint256 finalBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token
		);

		_amt = sub(finalBal, initialBal);

		convertWethToEth(isEth, tokenContract, _amt);

		setUint(setId, _amt);

		_eventName = "LogWithdrawFrom(address,address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, from, to, _amt, getId, setId);
	}

	/**
	 * @dev Borrow base asset.
	 * @notice Withdraw base token from Compound.
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
		bool success = _withdraw(market, token, 0x00, 0x00, _amt);;
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

	/**
	 * @dev Borrow base asset and transfer to 'to' account.
	 * @notice Withdraw base token from Compound on behalf of an address.
	 * @param market The address of the market from where to withdraw.
     * @param to The address to which the borrowed asset is transferred.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function borrowOnBehalf(
		address market,
        address to,
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
		bool success = _withdraw(market, token, 0x00, to, _amt);
		require(success, "borrow-failed");

		uint256 finalBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token
		);

		_amt = sub(finalBal, initialBal);

		convertWethToEth(isEth, tokenContract, _amt);

		setUint(setId, _amt);

		_eventName = "LogBorrowOnBehalf(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, to, _amt, getId, setId);
	}

	/**
	 * @dev Borrow base asset from 'from' and transfer to 'to'.
	 * @notice Withdraw base token or deposited token from Compound.
	 * @param market The address of the market from where to withdraw.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
     * @param from The address from where asset is to be withdrawed.
     * @param to The address to which the borrowed assets are to be transferred.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function borrowFrom(
		address market,
        address from,
        address to,
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
		bool success = _withdraw(market, token, from, to, _amt);
		require(success, "borrow-failed");

		uint256 finalBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token
		);

		_amt = sub(finalBal, initialBal);

		convertWethToEth(isEth, tokenContract, _amt);

		setUint(setId, _amt);

		_eventName = "LogBorrowFrom(address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, from, to, _amt, getId, setId);
	}

    /**
	 * @dev Repays entire borrow of the base asset.
	 * @notice Repays an entire borrow of the base asset.
	 * @param market The address of the market from where to withdraw.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
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

		bool success = _supply(market, _token, 0x00, 0x00, _amt);
		require(success, "supply-failed");

		setUint(setId, _amt);

		_eventName = "LogPayback(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, _amt, getId, setId);
	}

    /**
	 * @dev Repays entire borrow of the base asset on behalf of 'to'.
	 * @notice Repays an entire borrow of the base asset on behalf of 'to'.
	 * @param market The address of the market from where to withdraw.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
     * @param to The address on behalf of which the borrow is to be repaid.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function payBackOnBehalf(
		address market,
		address to,
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

		bool success = _supply(market, _token, 0x00, to, _amt);
		require(success, "supply-failed");

		setUint(setId, _amt);

		_eventName = "LogPaybackOnBehalf(address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, to, _amt, getId, setId);
	}

    /**
	 * @dev Repays entire borrow of the base asset form 'from' on behalf of 'to'.
	 * @notice Repays an entire borrow of the base asset on behalf of 'to'.
	 * @param market The address of the market from where to withdraw.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
     * @param from The address from which the borrow has to be repaid on behalf of 'to'.
     * @param to The address on behalf of which the borrow is to be repaid.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function payFrom(
		address market,
		address from,
        address to,
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

		bool success = _supply(market, _token, from, to, _amt);
		require(success, "supply-failed");

		setUint(setId, _amt);

		_eventName = "LogPaybackFrom(address,address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, from, to, _amt, getId, setId);
	}

}

contract ConnectV3Compound is CompoundResolver {
	string public name = "Compound-v1.0";
}
