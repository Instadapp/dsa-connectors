//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Basic D.
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
	 * @param minSharesPerToken The min share rate of deposit. Should always be in 18 decimals.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function deposit(
		address vaultToken,
		uint256 underlyingAmt,
		uint256 minSharesPerToken,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _underlyingAmt = getUint(getId, underlyingAmt);

		IERC4626 vaultTokenContract = IERC4626(vaultToken);
		TokenInterface _underlyingTokenContract = TokenInterface(
			vaultTokenContract.asset()
		);

		_underlyingAmt = _underlyingAmt == uint256(-1)
			? _underlyingTokenContract.balanceOf(address(this))
			: _underlyingAmt;

		// Returns final amount in token decimals.
		uint256 _minShares = wmul(minSharesPerToken, _underlyingAmt);

		// Initial share balance
		uint256 _initialVaultBal = vaultTokenContract.balanceOf(address(this));

		approve(_underlyingTokenContract, vaultToken, _underlyingAmt);

		// Deposit tokens for shares
		vaultTokenContract.deposit(_underlyingAmt, address(this));

		uint256 _sharesReceieved = sub(
			vaultTokenContract.balanceOf(address(this)),
			_initialVaultBal
		);

		require(_minShares <= _sharesReceieved, "Less shares received");

		setUint(setId, _sharesReceieved);

		_eventName = "LogDeposit(address,uint256,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			vaultToken,
			_underlyingAmt,
			minSharesPerToken,
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
	 * @param maxTokenPerShares The max underyling token rate of mint. Always in 18 decimals.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens minted.
	 */
	function mint(
		address vaultToken,
		uint256 shareAmt,
		uint256 maxTokenPerShares,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _shareAmt = getUint(getId, shareAmt);

		IERC4626 vaultTokenContract = IERC4626(vaultToken);
		TokenInterface underlyingTokenContract = TokenInterface(
			vaultTokenContract.asset()
		);

		_shareAmt = _shareAmt == uint256(-1)
			? vaultTokenContract.balanceOf(address(this))
			: _shareAmt;

		// Returns final amount in token decimals.
		uint256 _maxTokens = wmul(maxTokenPerShares, _shareAmt);

		uint256 _underlyingTokenAmount = vaultTokenContract.previewMint(
			_shareAmt
		);

		uint256 _initalUnderlyingBal = underlyingTokenContract.balanceOf(
			address(this)
		);

		approve(underlyingTokenContract, vaultToken, _underlyingTokenAmount);

		// Mint shares for tokens
		vaultTokenContract.mint(_shareAmt, address(this));

		uint256 _tokensDeducted = sub(
			_initalUnderlyingBal,
			underlyingTokenContract.balanceOf(address(this))
		);

		require(_maxTokens >= _tokensDeducted, "maxTokenPerShares-exceeds");

		setUint(setId, _shareAmt);

		_eventName = "LogMint(address,uint256,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			vaultToken,
			_shareAmt,
			maxTokenPerShares,
			_tokensDeducted,
			getId,
			setId
		);
	}

	/**
	 * @dev Withdraw underlying asset from ERC4626 Vault.
	 * @notice Withdraw vault shares with exactly amount of underlying assets
	 * @param vaultToken ERC4626 Token address.
	 * @param underlyingAmt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param maxSharesPerToken The max share rate of withdrawn amount. Always send in 18 decimals.
	 * @param to The address of receiver.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdraw(
		address vaultToken,
		uint256 underlyingAmt,
		uint256 maxSharesPerToken,
		address payable to,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _underlyingAmt = getUint(getId, underlyingAmt);

		IERC4626 vaultTokenContract = IERC4626(vaultToken);
		TokenInterface underlyingTokenContract = TokenInterface(
			vaultTokenContract.asset()
		);

		_underlyingAmt = _underlyingAmt == uint256(-1)
			? underlyingTokenContract.balanceOf(address(this))
			: _underlyingAmt;

		// Returns final amount in token decimals.
		uint256 _maxShares = wmul(maxSharesPerToken, _underlyingAmt);

		uint256 _initialVaultBal = vaultTokenContract.balanceOf(to);

		// Withdraw tokens for shares
		vaultTokenContract.withdraw(_underlyingAmt, to, address(this));

		uint256 _sharesBurned = sub(_initialVaultBal, vaultTokenContract.balanceOf(to));

		require(_maxShares >= _sharesBurned, "maxShares-exceeds");

		setUint(setId, _underlyingAmt);

		_eventName = "LogWithdraw(address,uint256,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			vaultToken,
			_underlyingAmt,
			maxSharesPerToken,
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
	 * @param minTokenPerShares The min underlying token rate of withdraw. Always in 18 decimals.
	 * @param to The address of receiver.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens redeem.
	 */

	function redeem(
		address vaultToken,
		uint256 shareAmt,
		uint256 minTokenPerShares,
		address payable to,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _shareAmt = getUint(getId, shareAmt);

		IERC4626 vaultTokenContract = IERC4626(vaultToken);
		TokenInterface underlyingTokenContract = TokenInterface(
			vaultTokenContract.asset()
		);

		_shareAmt = _shareAmt == uint256(-1)
			? vaultTokenContract.balanceOf(address(this))
			: _shareAmt;

		// Returns final amount in token decimals.
		uint256 _minUnderlyingAmt = wmul(minTokenPerShares, _shareAmt);

		uint256 _initalUnderlyingBal = underlyingTokenContract.balanceOf(to);

		// Redeem tokens for shares
		vaultTokenContract.redeem(_shareAmt, to, address(this));

		uint256 _underlyingAmtReceieved = sub(
			underlyingTokenContract.balanceOf(to),
			_initalUnderlyingBal
		);

		require(_minUnderlyingAmt <= _underlyingAmtReceieved, "_minUnderlyingAmt-exceeds");

		setUint(setId, _shareAmt);

		_eventName = "LogRedeem(address,uint256,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			vaultToken,
			_shareAmt,
			minTokenPerShares,
			_underlyingAmtReceieved,
			to,
			getId,
			setId
		);
	}
}

contract ConnectV2BasicERC4626 is BasicConnector {
	string public constant name = "BASIC-ERC4626-v1.0";
}