//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Basic D V2.
 * @dev Deposit, Mint, Withdraw, & Redeem from ERC4626 DSA.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "./interface.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";

abstract contract BasicConnector is Events, DSMath, Basic {

	/**
	 * @dev Deposit underlying asset to ERC4626 Vault.
	 * @notice Mints vault shares by depositing exactly amount of underlying assets
	 * @param vaultToken ERC4626 Token address.
	 * @param underlyingAmt The amount of the underlying asset to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	*/
	function deposit(
		address vaultToken,
		uint256 underlyingAmt,
		uint256 getId,
		uint256 setId
	) public payable returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _underlyingAmt = getUint(getId, underlyingAmt);

		IERC4626 vaultTokenContract = IERC4626(vaultToken);
		TokenInterface _underlyingTokenContract = TokenInterface(
			vaultTokenContract.asset()
		);

		_underlyingAmt = _underlyingAmt == uint256(-1)
			? _underlyingTokenContract.balanceOf(address(this))
			: _underlyingAmt;

		approve(_underlyingTokenContract, vaultToken, _underlyingAmt);

		// Deposit tokens for shares
		uint256 _sharesReceieved =
			vaultTokenContract.deposit(_underlyingAmt, address(this));

		setUint(setId, _sharesReceieved);

		_eventName = "LogDeposit(address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			vaultToken,
			_underlyingAmt,
			_sharesReceieved,
			getId,
			setId
		);
	}

	/**
	 * @dev Mint underlying asset to ERC4626 Vault.
	 * @notice Mints vault shares by minting exactly amount of underlying assets
	 * @param vaultToken ERC4626 Token address.
	 * @param shareAmt The amount of the share to mint. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens minted.
	 */
	function mint(
		address vaultToken,
		uint256 shareAmt,
		uint256 getId,
		uint256 setId
	) public payable returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _shareAmt = getUint(getId, shareAmt);

		IERC4626 vaultTokenContract = IERC4626(vaultToken);
		TokenInterface underlyingTokenContract = TokenInterface(
			vaultTokenContract.asset()
		);

		uint256 _underlyingTokenAmount = vaultTokenContract.previewMint(
			_shareAmt
		);

		approve(underlyingTokenContract, vaultToken, _underlyingTokenAmount);

		// Mint shares for tokens
		uint256 _tokensDeposited = 
			vaultTokenContract.mint(_shareAmt, address(this));

		setUint(setId, _tokensDeposited);

		_eventName = "LogMint(address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			vaultToken,
			_shareAmt,
			_tokensDeposited,
			getId,
			setId
		);
	}

	/**
	 * @dev Withdraw underlying asset from ERC4626 Vault.
	 * @notice Withdraw vault shares with exactly amount of underlying assets
	 * @param vaultToken ERC4626 Token address.
	 * @param underlyingAmt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param to The address of receiver.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdraw(
		address vaultToken,
		uint256 underlyingAmt,
		address payable to,
		uint256 getId,
		uint256 setId
	) public payable returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _underlyingAmt = getUint(getId, underlyingAmt);

		IERC4626 vaultTokenContract = IERC4626(vaultToken);
		TokenInterface underlyingTokenContract = TokenInterface(
			vaultTokenContract.asset()
		);

		_underlyingAmt = _underlyingAmt == uint256(-1)
			? underlyingTokenContract.balanceOf(address(this))
			: _underlyingAmt;

		// Withdraw tokens for shares
		uint256 _sharesBurned =
			vaultTokenContract.withdraw(_underlyingAmt, to, address(this));

		setUint(setId, _underlyingAmt);

		_eventName = "LogWithdraw(address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			vaultToken,
			_underlyingAmt,
			_sharesBurned,
			to,
			getId,
			setId
		);
	}

	/**
	 * @dev Redeem underlying asset from ERC4626 Vault.
	 * @notice Redeem vault shares with exactly amount of underlying assets
	 * @param vaultToken ERC4626 Token address.
	 * @param shareAmt The amount of the token to redeem. (For max: `uint256(-1)`)
	 * @param to The address of receiver.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens redeem.
	 */

	function redeem(
		address vaultToken,
		uint256 shareAmt,
		address payable to,
		uint256 getId,
		uint256 setId
	) public payable returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _shareAmt = getUint(getId, shareAmt);

		IERC4626 vaultTokenContract = IERC4626(vaultToken);
		TokenInterface underlyingTokenContract = TokenInterface(
			vaultTokenContract.asset()
		);

		_shareAmt = _shareAmt == uint256(-1)
			? vaultTokenContract.balanceOf(address(this))
			: _shareAmt;

		// Redeem tokens for shares
		uint256 _underlyingAmtReceieved =
			vaultTokenContract.redeem(_shareAmt, to, address(this));

		setUint(setId, _shareAmt);

		_eventName = "LogRedeem(address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			vaultToken,
			_shareAmt,
			_underlyingAmtReceieved,
			to,
			getId,
			setId
		);
	}
}

contract ConnectV2BasicERC4626V2 is BasicConnector {
	string public constant name = "BASIC-ERC4626-v2.0";
}