//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Basic D.
 * @dev Deposit & Mint & Withdraw & Redeem from DSA.
 */

// import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC4626 } from "./interface.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";

abstract contract BasicResolver is Events, DSMath, Basic {
	/**
	 * @dev Deposit ERC4626_Token asset.
	 * @notice Deposit a token to DSA.
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
		public
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);
		IERC4626 tokenContract = IERC4626(token);

		_amt = _amt == uint256(-1)
			? tokenContract.balanceOf(address(this))
			: _amt;

		try tokenContract.approve(tokenContract.asset(), _amt) {} catch {
			tokenContract.approve(tokenContract.asset(), 0);
			tokenContract.approve(tokenContract.asset(), _amt);
		}
		// approve(tokenContract, tokenContract.asset(), _amt);
		tokenContract.deposit(_amt, address(this));
		setUint(setId, _amt);

		_eventName = "LogDeposit(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);
	}

	/**
	 * @dev Mint ERC4626_Token share.
	 * @notice Mint a token to DSA.
	 * @param token The address of the token to mint.
	 * @param amt The amount of the token to mint. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens minted.
	 */

	function mint(
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _amt = getUint(getId, amt);
		IERC4626 tokenContract = IERC4626(token);

		_amt = _amt == uint256(-1)
			? tokenContract.balanceOf(address(this))
			: _amt;

		try tokenContract.approve(tokenContract.asset(), _amt) {} catch {
			tokenContract.approve(tokenContract.asset(), 0);
			tokenContract.approve(tokenContract.asset(), _amt);
		}
		// approve(tokenContract, tokenContract.asset(), _amt);
		tokenContract.mint(_amt, address(this));
		setUint(setId, _amt);

		_eventName = "LogDeposit(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);
	}

	/**
	 * @dev Withdraw ERC4626_Token.
	 * @notice Withdraw a token to DSA.
	 * @param token The address of the token to withdraw.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
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
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);
		IERC4626 tokenContract = IERC4626(token);

		_amt = _amt == uint256(-1)
			? tokenContract.balanceOf(address(this))
			: _amt;

		tokenContract.withdraw(_amt, to, address(this));
		setUint(setId, _amt);

	    _eventName = "LogWithdraw(address,uint256,address,uint256,uint256)";
	    _eventParam = abi.encode(token, _amt, to, getId, setId);
	}

	/**
	 * @dev Redeem ERC4626_Token.
	 * @notice Reddem a token to DSA.
	 * @param token The address of the token to redeem.
	 * @param amt The amount of the token to redeem. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens redeemed.
	 */

	function redeem(
		address token,
		uint256 amt,
	    address payable to,
		uint256 getId,
		uint256 setId
	)
		public
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);
		IERC4626 tokenContract = IERC4626(token);

		_amt = _amt == uint256(-1)
			? tokenContract.balanceOf(address(this))
			: _amt;

		tokenContract.redeem(_amt, to, address(this));
		setUint(setId, _amt);

	    _eventName = "LogRedeem(address,uint256,address,uint256,uint256)";
	    _eventParam = abi.encode(token, _amt, to, getId, setId);
	}
}

contract ConnectV2BasicERC4626 is BasicResolver {
	string public constant name = "BASIC-ERC4626-v1.0";
}
