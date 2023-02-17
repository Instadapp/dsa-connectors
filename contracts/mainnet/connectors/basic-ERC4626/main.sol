//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Basic.
 * @dev Deposit & Withdraw from DSA.
 */

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC4626 } from "./IERC4626.sol";

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";

abstract contract BasicResolver is Events, DSMath, Basic {
	using SafeERC20 for IERC4626;

	/**
	 * @dev Deposit Assets To Smart Account From any user.
	 * @notice Deposit a token to DSA from any user.
	 * @param token The address of the token to deposit.
	 * @param amt The amount of tokens to deposit. (For max: `uint256(-1)`)
	 * @param from The address depositing the token.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function deposit(
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
		uint _amt = getUint(getId, amt);
		IERC4626 tokenContract = IERC4626(token);
		_amt = _amt == uint(-1) ? tokenContract.balanceOf(from) : _amt;
		uint _shares = tokenContract.deposit(_amt, from);

		setUint(setId, _shares);

		_eventName = "LogDeposit(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, from, getId, setId);
	}

	function mint(
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
		uint _amt = getUint(getId, amt);
		IERC4626 tokenContract = IERC4626(token);
		_amt = _amt == uint(-1) ? tokenContract.balanceOf(from) : _amt;
		uint _shares = tokenContract.mint(_amt, from);

		setUint(setId, _shares);

		_eventName = "LogMint(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, from, getId, setId);
	}

	/**
	 * @dev Withdraw Assets from Smart  Account
	 * @notice Withdraw a token from DSA
	 * @param token The address of the token to withdraw.
	 * @param amt The amount of tokens to withdraw. (For max: `uint256(-1)`)
	 * @param receiver The address to receive the token upon withdrawal
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdraw(
		address token,
		uint amt,
		address receiver,
		address owner,
		uint getId,
		uint setId
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint _amt = getUint(getId, amt);
		
		IERC4626 tokenContract = IERC4626(token);
		_amt = _amt == uint(-1)
			? tokenContract.balanceOf(address(this))
			: _amt;
		uint _shares = tokenContract.withdraw(_amt, receiver, owner);

		setUint(setId, _shares);

		_eventName = "LogWithdraw(address,uint256,address,address,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, receiver, owner, getId, setId);
	}

	function redeem(
		address token,
		uint amt,
		address receiver,
		address owner,
		uint getId,
		uint setId
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint _amt = getUint(getId, amt);
		
		IERC4626 tokenContract = IERC4626(token);
		_amt = _amt == uint(-1)
			? tokenContract.balanceOf(address(this))
			: _amt;
		uint _shares = tokenContract.redeem(_amt, receiver, owner);

		setUint(setId, _shares);

		_eventName = "LogRedeem(address,uint256,address,address,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, receiver, owner, getId, setId);
	}
}

contract ConnectV2Basic is BasicResolver {
	string public constant name = "BASIC-ERC4626-A";
}
