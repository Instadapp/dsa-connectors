//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title InstaLite Connector
 * @dev Supply and Withdraw

 */
import { TokenInterface } from "../../common/interfaces.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";
import { instaLiteInterface } from "./interface.sol";

abstract contract InstaLiteConnector is Events, Basic {
	/**
	 * @dev Supply
	 * @notice Supply eth/weth/stEth tokens into instalite.
	 * @param vaultAddress Address of instaLite Contract.
	 * @param token The address of token to be supplied.
	 * @param amt The amount of token to be supplied.
	 * @param to The address of the account on behalf of you want to supplied.
	 * @param getId ID to retrieve amt.
	 * @param setIds ID stores the amount of token deposited.
	 */
	function supply(
		address vaultAddress,
		address token,
		uint256 amt,
		address to,
		uint256 getId,
		uint256[] memory setIds
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);
		bool isEth = token == ethAddr;
		uint256 vTokenAmt;

		instaLiteInterface instaLiteInstance = instaLiteInterface(vaultAddress);

		if (isEth) {
			_amt = _amt == uint256(-1) ? address(this).balance : _amt;
			vTokenAmt = instaLiteInstance.supplyEth{ value: amt }(to);
		} else {
			TokenInterface tokenContract = TokenInterface(token);

			_amt = _amt == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: _amt;

			approve(tokenContract, vaultAddress, _amt);
			vTokenAmt = instaLiteInstance.supply(token, _amt, to);
		}

		setUint(setIds[0], _amt);
		setUint(setIds[1], vTokenAmt);

		_eventName = "LogSupply(address,address,uint256,uint256,address,uint256,uint256[])";
		_eventParam = abi.encode(
			vaultAddress,
			token,
			vTokenAmt,
			_amt,
			to,
			getId,
			setIds
		);
	}

	/**
	 * @dev Withdraw
	 * @notice Withdraw eth/stEth tokens from instalite contract.
	 * @param vaultAddress Address of vaultAddress Contract.
	 * @param amt The amount of the token to withdraw.
	 * @param to The address of the account on behalf of you want to withdraw.
	 * @param getId ID to retrieve amt.
	 * @param setIds ID stores the amount of token withdrawn.
	 */
	function withdraw(
		address vaultAddress,
		uint256 amt,
		address to,
		uint256 getId,
		uint256[] memory setIds
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		instaLiteInterface instaLiteInstance = instaLiteInterface(vaultAddress);

		uint256 vTokenAmt = instaLiteInstance.withdraw(_amt, to);

		setUint(setIds[0], _amt);
		setUint(setIds[1], vTokenAmt);

		_eventName = "LogWithdraw(address,uint256,uint256,address,uint256,uint256[])";
		_eventParam = abi.encode(
			vaultAddress,
			_amt,
			vTokenAmt,
			to,
			getId,
			setIds
		);
	}
}

contract ConnectV2InstaLiteVault1 is InstaLiteConnector {
	string public constant name = "instaLite-v1";
}
