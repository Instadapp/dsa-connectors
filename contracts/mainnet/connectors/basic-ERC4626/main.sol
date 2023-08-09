//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Basic D.
 * @dev Deposit, Mint, Withdraw, & Redeem from ERC4626 DSA.
 */

// import { IERC4626 } from "@openzeppelin/contracts-latest/interfaces/IERC4626.sol";
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
		IERC4626 vaultTokenContract = IERC4626(token);

		address _underlyingToken = vaultTokenContract.asset();
		TokenInterface underlyingTokenContract = TokenInterface(_underlyingToken);

		_amt = _amt == uint256(-1) ? underlyingTokenContract.balanceOf(address(this)) : _amt;

		approve(underlyingTokenContract, token, _amt);

		vaultTokenContract.deposit(_amt, address(this));
		setUint(setId, _amt);

		_eventName = "LogDeposit(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);
	}
	/**
	 * @dev Mint underlying asset to ERC4626 Vault.
	 * @notice Mints vault shares by minting exactly amount of underlying assets
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
		IERC4626 vaultTokenContract = IERC4626(token);

		address _underlyingToken = vaultTokenContract.asset();
		TokenInterface underlyingTokenContract = TokenInterface(_underlyingToken);

		_amt = _amt == uint256(-1) ? underlyingTokenContract.balanceOf(address(this)) : _amt;

		uint256 _approveUnderlyingTokenAmount = vaultTokenContract.previewMint(_amt);

		approve(underlyingTokenContract, token, _approveUnderlyingTokenAmount);

		vaultTokenContract.mint(_amt, address(this));
		setUint(setId, _amt);

		_eventName = "LogDeposit(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, getId, setId);

	}

	/**
	 * @dev Withdraw underlying asset from ERC4626 Vault.
	 * @notice Withdraw vault shares with exactly amount of underlying assets
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
		IERC4626 vaultTokenContract = IERC4626(token);

		address _underlyingToken = vaultTokenContract.asset();
		TokenInterface underlyingTokenContract = TokenInterface(_underlyingToken);

		_amt = _amt == uint256(-1)
			? underlyingTokenContract.balanceOf(address(this))
			: _amt;

		vaultTokenContract.withdraw(_amt, to, address(this));
		setUint(setId, _amt);

		_eventName = "LogWithdraw(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, to, getId, setId);

	}

	/**
	 * @dev Redeem underlying asset from ERC4626 Vault.
	 * @notice Redeem vault shares with exactly amount of underlying assets
	 * @param token ERC4626 Token address.
	 * @param amt The amount of the token to redeem. (For max: `uint256(-1)`)
	 * @param to The address of receiver.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens redeem.
	 */

	function redeem(
		address token,
		uint256 amt,
		address payable to,
		uint256 getId,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _amt = getUint(getId, amt);
		IERC4626 vaultTokenContract = IERC4626(token);

		address _underlyingToken = vaultTokenContract.asset();
		TokenInterface underlyingTokenContract = TokenInterface(_underlyingToken);

		_amt = _amt == uint256(-1)
			? underlyingTokenContract.balanceOf(address(this))
			: _amt;

		vaultTokenContract.redeem(_amt, to, address(this));
		setUint(setId, _amt);

		_eventName = "LogWithdraw(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(token, _amt, to, getId, setId);
	}
}

contract ConnectV2BasicERC4626 is BasicConnector {
	string public constant name = "BASIC-ERC4626-v1.0";
}
