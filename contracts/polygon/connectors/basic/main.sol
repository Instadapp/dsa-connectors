//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Basic.
 * @dev Deposit & Withdraw from DSA.
 */

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";

abstract contract BasicResolver is Events, DSMath, Basic {
	using SafeERC20 for IERC20;

	/**
	 * @dev Deposit Assets To Smart Account.
	 * @notice Deposit a token to DSA
	 * @param token The address of the token to deposit. (For MATIC: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of tokens to deposit. (For max: `uint256(-1)` (Not valid for MATIC))
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function deposit(
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
		if (token != maticAddr) {
			IERC20 tokenContract = IERC20(token);
			_amt = _amt == uint256(-1)
				? tokenContract.balanceOf(msg.sender)
				: _amt;
			tokenContract.safeTransferFrom(msg.sender, address(this), _amt);
		} else {
			require(
				msg.value == _amt || _amt == uint256(-1),
				"invalid-ether-amount"
			);
			_amt = msg.value;
		}
		setUint(setId, _amt);

		_eventName = "LogDeposit(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);
	}

	/**
	 * @dev Deposit Assets To Smart Account From any user.
	 * @notice Deposit a token to DSA from any user.
	 * @param token The address of the token to deposit. (Note: MATIC is not supported. Use `deposit()`)
	 * @param amt The amount of tokens to deposit. (For max: `uint256(-1)`)
	 * @param from The address depositing the token.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function depositFrom(
		address token,
		uint256 amt,
		address from,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);
		require(token != maticAddr, "eth-not-supported");
		IERC20 tokenContract = IERC20(token);
		_amt = _amt == uint256(-1) ? tokenContract.balanceOf(from) : _amt;
		tokenContract.safeTransferFrom(from, address(this), _amt);

		setUint(setId, _amt);

		_eventName = "LogDepositFrom(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, from, getId, setId);
	}

	/**
	 * @dev Withdraw Assets from Smart  Account
	 * @notice Withdraw a token from DSA
	 * @param token The address of the token to withdraw. (For MATIC: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of tokens to withdraw. (For max: `uint256(-1)`)
	 * @param to The address to receive the token upon withdrawal
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdraw(
		address token,
		uint256 amt,
		address payable to,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);
		if (token == maticAddr) {
			_amt = _amt == uint256(-1) ? address(this).balance : _amt;
			to.call{ value: _amt }("");
		} else {
			IERC20 tokenContract = IERC20(token);
			_amt = _amt == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: _amt;
			tokenContract.safeTransfer(to, _amt);
		}
		setUint(setId, _amt);

		_eventName = "LogWithdraw(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, to, getId, setId);
	}
}

contract ConnectV2BasicPolygon is BasicResolver {
	string public constant name = "Basic-v1.1";
}
