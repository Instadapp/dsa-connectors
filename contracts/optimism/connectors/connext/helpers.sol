//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { IConnext } from "./interface.sol";
import { IInstaReceiver } from "./interface.sol";

contract Helpers is DSMath, Basic {
  /**
   * @dev Connext Diamond Address
   */
  address internal constant connextAddr = 0x8f7492DE823025b4CfaAB1D34c58963F2af5DEDA;
	IConnext internal constant connext = IConnext(connextAddr);

  /**
   * @dev InstaReceiver Address
   */
	address internal constant instaReceiverAddr = 0x0000000000000000000000000000000000000000; // TODO: Add InstaReceiver address
	IInstaReceiver internal constant instaReceiver = IInstaReceiver(instaReceiverAddr);

	/**
	 * @param destination The destination domain ID.
	 * @param asset The address of token to be bridged.
	 * @param delegate Address that can revert or forceLocal on destination.
	 * @param amount The amount to transfer.
	 * @param slippage Maximum amount of slippage the user will accept in BPS.
	 * @param relayerFee Relayer fee paid in origin native asset.
	 * @param callData Encoded calldata to send.
	 */
	struct XCallParams {
    uint32 destination;
    address to;
    address asset;
    address delegate;
    uint256 amount;
    uint256 slippage;
    uint256 relayerFee;
    bytes callData;
	}

	function _xcall(XCallParams memory params) internal {
		uint256 nativeTokenAmt;
		bool isNative = params.asset == ethAddr;

		if (isNative) {
			params.amount = params.amount == uint256(-1)
				? address(this).balance
				: params.amount;

			// xcall does not take native asset, must wrap 
			TokenInterface tokenContract = TokenInterface(wethAddr);
			convertEthToWeth(true, tokenContract, params.amount);

			nativeTokenAmt = params.amount;
		} else {
			TokenInterface tokenContract = TokenInterface(params.asset);
			params.amount = params.amount == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: params.amount;

			if (params.amount > 0) {
				tokenContract.approve(connextAddr, params.amount);
			}

			nativeTokenAmt = 0;
		}

		connext.xcall{ value: params.relayerFee + nativeTokenAmt }(
			params.destination,
			params.to,
      params.asset,
			params.delegate,
			params.amount,
			params.slippage,
			params.callData
		);
	}
}
