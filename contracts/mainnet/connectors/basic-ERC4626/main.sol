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
	 * @param token ERC4626 Token address.
	 * @param underlyingAmt The amount of the underlying asset to deposit. (For max: `uint256(-1)`)
	 * @param minSharesPerToken The min share rate of deposit
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */

	function deposit(
		address token,
		uint256 underlyingAmt,
		uint256 minSharesPerToken,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _underlyingAmt = getUint(getId, underlyingAmt);
		IERC4626 vaultTokenContract = IERC4626(token);

		address _underlyingToken = vaultTokenContract.asset();
		uint8 _vaultShareDecimal = vaultTokenContract.decimals();
		TokenInterface underlyingTokenContract = TokenInterface(
			_underlyingToken
		);

		_underlyingAmt = _underlyingAmt == uint256(-1)
			? underlyingTokenContract.balanceOf(address(this))
			: _underlyingAmt;

		uint256 _minShares = convert18ToDec(
			_vaultShareDecimal,
			wmul(minSharesPerToken, _underlyingAmt)
		);

		uint256 _initialVaultBal = vaultTokenContract.balanceOf(address(this));

		approve(underlyingTokenContract, token, _underlyingAmt);
		vaultTokenContract.deposit(_underlyingAmt, address(this));

		uint256 _finalVaultBal = vaultTokenContract.balanceOf(address(this));

		require(
			_minShares <= sub(_finalVaultBal, _initialVaultBal),
			"minShares-exceeds"
		);

		setUint(setId, _underlyingAmt);

		_eventName = "LogDeposit(address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			token,
			_underlyingAmt,
			minSharesPerToken,
			getId,
			setId
		);
	}

	/**
	 * @dev Mint underlying asset to ERC4626 Vault.
	 * @notice Mints vault shares by minting exactly amount of underlying assets
	 * @param token ERC4626 Token address.
	 * @param shareAmt The amount of the share to mint. (For max: `uint256(-1)`)
	 * @param maxTokenPerShares The max underyling token rate of mint
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens minted.
	 */

	function mint(
		address token,
		uint256 shareAmt,
		uint256 maxTokenPerShares,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _shareAmt = getUint(getId, shareAmt);
		IERC4626 vaultTokenContract = IERC4626(token);

		address _underlyingToken = vaultTokenContract.asset();
		uint8 _vaultShareDecimal = vaultTokenContract.decimals();
		TokenInterface underlyingTokenContract = TokenInterface(
			_underlyingToken
		);

		_shareAmt = _shareAmt == uint256(-1)
			? vaultTokenContract.balanceOf(address(this))
			: _shareAmt;

		maxTokenPerShares = convertTo18(
			_vaultShareDecimal,
			wmul(maxTokenPerShares, _shareAmt)
		);

		uint256 _approveUnderlyingTokenAmount = vaultTokenContract.previewMint(
			_shareAmt
		);

		uint256 _initalUnderlyingBal = IERC20(_underlyingToken).balanceOf(
			address(this)
		);

		approve(underlyingTokenContract, token, _approveUnderlyingTokenAmount);

		vaultTokenContract.mint(_shareAmt, address(this));

		uint256 _finalUnderlyingBal = IERC20(_underlyingToken).balanceOf(
			address(this)
		);

		require(
			maxTokenPerShares >= sub(_initalUnderlyingBal, _finalUnderlyingBal),
			"maxUnderlyingAmt-exceeds"
		);

		setUint(setId, _shareAmt);

		_eventName = "LogMint(address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			token,
			_shareAmt,
			maxTokenPerShares,
			getId,
			setId
		);
	}

	/**
	 * @dev Withdraw underlying asset from ERC4626 Vault.
	 * @notice Withdraw vault shares with exactly amount of underlying assets
	 * @param token ERC4626 Token address.
	 * @param underlyingAmt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param maxSharesPerToken The max share rate of withdrawn amount.
	 * @param to The address of receiver.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */

	function withdraw(
		address token,
		uint256 underlyingAmt,
		uint256 maxSharesPerToken,
		address payable to,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _underlyingAmt = getUint(getId, underlyingAmt);
		IERC4626 vaultTokenContract = IERC4626(token);

		address _underlyingToken = vaultTokenContract.asset();
		uint8 _vaultShareDecimal = vaultTokenContract.decimals();
		TokenInterface underlyingTokenContract = TokenInterface(
			_underlyingToken
		);

		_underlyingAmt = _underlyingAmt == uint256(-1)
			? underlyingTokenContract.balanceOf(address(this))
			: _underlyingAmt;

		uint256 _maxShares = convert18ToDec(
			_vaultShareDecimal,
			wmul(maxSharesPerToken, _underlyingAmt)
		);

		uint256 _initialVaultBal = vaultTokenContract.balanceOf(to);

		vaultTokenContract.withdraw(_underlyingAmt, to, address(this));

		uint256 _finalVaultBal = vaultTokenContract.balanceOf(to);

		require(
			_maxShares >= sub(_finalVaultBal, _initialVaultBal),
			"minShares-exceeds"
		);

		setUint(setId, _underlyingAmt);

		_eventName = "LogWithdraw(address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			token,
			_underlyingAmt,
			maxSharesPerToken,
			to,
			getId,
			setId
		);
	}

	/**
	 * @dev Redeem underlying asset from ERC4626 Vault.
	 * @notice Redeem vault shares with exactly amount of underlying assets
	 * @param token ERC4626 Token address.
	 * @param shareAmt The amount of the token to redeem. (For max: `uint256(-1)`)
	 * @param minTokenPerShares The min underlying token rate of withdraw.
	 * @param to The address of receiver.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens redeem.
	 */

	function redeem(
		address token,
		uint256 shareAmt,
		uint256 minTokenPerShares,
		address payable to,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _shareAmt = getUint(getId, shareAmt);
		IERC4626 vaultTokenContract = IERC4626(token);

		address _underlyingToken = vaultTokenContract.asset();
		uint8 _vaultShareDecimal = vaultTokenContract.decimals();
		TokenInterface underlyingTokenContract = TokenInterface(
			_underlyingToken
		);

		_shareAmt = _shareAmt == uint256(-1)
			? vaultTokenContract.balanceOf(address(this))
			: _shareAmt;

		uint256 _minUnderlyingAmt = convert18ToDec(
			_vaultShareDecimal,
			wmul(minTokenPerShares, _shareAmt)
		);
				
		uint256 _initalUnderlyingBal = IERC20(_underlyingToken).balanceOf(
			to
		);

		vaultTokenContract.redeem(_shareAmt, to, address(this));

		uint256 _finalUnderlyingBal = IERC20(_underlyingToken).balanceOf(
			to
		);

		require(
			_minUnderlyingAmt <= sub(_finalUnderlyingBal, _initalUnderlyingBal),
			"minTokens-exceeds"
		);
		setUint(setId, _shareAmt);

		_eventName = "LogRedeem(address,uint256,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			token,
			_shareAmt,
			minTokenPerShares,
			to,
			getId,
			setId
		);
	}
}

contract ConnectV2BasicERC4626 is BasicConnector {
	string public constant name = "BASIC-ERC4626-v1.0";
}
