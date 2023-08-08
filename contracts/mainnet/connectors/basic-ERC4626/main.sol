//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Basic D.
 * @dev Deposit & Mint & Withdraw & Redeem from DSA.
 */

// import { IERC4626 } from "@openzeppelin/contracts-latest/interfaces/IERC4626.sol";
import { IERC4626 } from "./interface.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";

abstract contract BasicResolver is Events, DSMath, Basic {
	/**
	 * @dev Deposit asset to ERC4626_Token.
	 * @notice Deposit a token to DSA.
	 * @param token ERC4626 Token address.
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */

	function deposit(
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _amt = getUint(getId, amt);
		IERC4626 tokenContract = IERC4626(token);

		address assetToken = tokenContract.asset();
		TokenInterface assetTokenContract = TokenInterface(assetToken);

		_amt = _amt == uint256(-1) ? assetTokenContract.balanceOf(token) : _amt;

		approve(assetTokenContract, token, _amt);

		tokenContract.deposit(_amt, msg.sender);
		setUint(setId, _amt);

		_eventName = "LogDeposit(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);
	}

	/**
	 * @dev Mint asset to ERC4626_Token.
	 * @notice Mint a token to DSA.
	 * @param token ERC4626 Token address.
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

		address assetToken = tokenContract.asset();
		TokenInterface assetTokenContract = TokenInterface(assetToken);

		_amt = _amt == uint256(-1) ? assetTokenContract.balanceOf(token) : _amt;

		approve(assetTokenContract, token, _amt);

		tokenContract.mint(_amt, msg.sender);
		setUint(setId, _amt);

		_eventName = "LogDeposit(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);
	}

	/**
	 * @dev Withdraw asset from ERC4626_Token.
	 * @notice Withdraw a token to DSA.
	 * @param token ERC4626 Token address.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param to The address of receiver.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */

	function withdraw(
		address token,
		uint256 amt,
		address payable to,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _amt = getUint(getId, amt);
		IERC4626 tokenContract = IERC4626(token);

		address assetToken = tokenContract.asset();
		TokenInterface assetTokenContract = TokenInterface(assetToken);

		_amt = _amt == uint256(-1)
			? assetTokenContract.balanceOf(msg.sender)
			: _amt;

		tokenContract.withdraw(_amt, to, msg.sender);
		setUint(setId, _amt);

		_eventName = "LogWithdraw(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, to, getId, setId);
	}

	/**
	 * @dev Redeem asset from ERC4626_Token.
	 * @notice Redeem a token to DSA.
	 * @param token ERC4626 Token address.
	 * @param amt The amount of the token to redeem. (For max: `uint256(-1)`)
	 * @param to The address of receiver.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens redeemed.
	 */

	function redeem(
		address token,
		uint256 amt,
		address payable to,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _amt = getUint(getId, amt);
		IERC4626 tokenContract = IERC4626(token);

		address assetToken = tokenContract.asset();
		TokenInterface assetTokenContract = TokenInterface(assetToken);

		_amt = _amt == uint256(-1)
			? assetTokenContract.balanceOf(msg.sender)
			: _amt;

		tokenContract.redeem(_amt, to, msg.sender);
		setUint(setId, _amt);

		_eventName = "LogWithdraw(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, to, getId, setId);
	}
}

contract ConnectV2BasicERC4626 is BasicResolver {
	string public constant name = "BASIC-ERC4626-v1.0";
}
