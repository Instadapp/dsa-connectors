pragma solidity ^0.7.0;

/**
 * @title WETH.
 * @dev Wrap and Unwrap WETH.
 */

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";
import { Helpers } from "./helpers.sol";

abstract contract Resolver is Events, DSMath, Basic, Helpers {
	/**
	 * @dev deposit ETH into Lido.
	 * @notice sends Eth into lido and in return you get equivalent of stEth tokens
	 * @param amt The amount of ETH to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of ETH deposited.
	 */
	function deposit(
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		_amt = _amt == uint256(-1) ? address(this).balance : _amt;
		lidoInterface.submit{ value: amt }(address(0));
		setUint(setId, _amt);

		_eventName = "LogDeposit(uint256,uint256,uint256)";
		_eventParam = abi.encode(_amt, getId, setId);
	}
}

contract ConnectV2LidoStEth is Resolver {
	string public constant name = "LidoStEth-v1.0";
}
