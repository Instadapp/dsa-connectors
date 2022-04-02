//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title InstaLite Connector
 * @dev Supply and Withdraw

 */
import { TokenInterface } from "../../common/interfaces.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";
import { IInstaLite } from "./interface.sol";

abstract contract InstaLiteConnector is Events, Basic {
	/**
	 * @dev Supply ETH/ERC20
	 * @notice Supply a token into Instalite.
	 * @param vaultAddress Address of instaLite Contract.
	 * @param token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of token to be supplied. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setIds ID stores the amount of token deposited.
	 */
	function supply(
		address vaultAddress,
		address token,
		uint256 amt,
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

		IInstaLite instaLite = IInstaLite(vaultAddress);

		if (isEth) {
			_amt = _amt == uint256(-1) ? address(this).balance : _amt;
			vTokenAmt = instaLite.supplyEth{ value: amt }(address(this));
		} else {
			TokenInterface tokenContract = TokenInterface(token);

			_amt = _amt == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: _amt;

			approve(tokenContract, vaultAddress, _amt);
			vTokenAmt = instaLite.supply(token, _amt, address(this));
		}

		setUint(setIds[0], _amt);
		setUint(setIds[1], vTokenAmt);

		_eventName = "LogSupply(address,address,uint256,uint256,uint256,uint256[])";
		_eventParam = abi.encode(
			vaultAddress,
			token,
			vTokenAmt,
			_amt,
			getId,
			setIds
		);
	}

	/**
	 * @dev Withdraw ETH/ERC20
	 * @notice Withdraw deposited tokens from Instalite.
	 * @param vaultAddress Address of vaultAddress Contract.
	 * @param amt The amount of the token to withdraw.
	 * @param getId ID to retrieve amt.
	 * @param setIds array of IDs to stores the amount of tokens withdrawn.
	 */
	function withdraw(
		address vaultAddress,
		uint256 amt,
		uint256 getId,
		uint256[] memory setIds
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		IInstaLite instaLite = IInstaLite(vaultAddress);

		uint256 vTokenAmt = instaLite.withdraw(_amt, address(this));

		setUint(setIds[0], _amt);
		setUint(setIds[1], vTokenAmt);

		_eventName = "LogWithdraw(address,uint256,uint256,uint256,uint256[])";
		_eventParam = abi.encode(vaultAddress, _amt, vTokenAmt, getId, setIds);
	}
}

contract ConnectV2InstaLiteVault1 is InstaLiteConnector {
	string public constant name = "instaLite-v1";
}
