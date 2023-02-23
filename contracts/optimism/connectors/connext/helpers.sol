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
	 * @param asset he address of token to be bridged.(For USDC: 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)
	 * @param delegate The address to recieve the token on destination chain.
	 * @param amount The total amount sent by user (Includes bonder fee, destination chain Tx cost).
	 * @param slippage The fee to be recieved by bonder at destination chain.
	 * @param relayerFee Relayer fee paid in origin native asset.
	 * @param callData minimum amount of token out for swap on source chain.
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
    TokenInterface tokenContract = TokenInterface(params.asset);

		bool isNative = params.asset == ethAddr;

		uint256 nativeTokenAmt;
		if (isNative) {
			params.amount = params.amount == uint256(-1)
				? address(this).balance
				: params.amount;

			// xcall does not take native asset, must wrap 
			convertEthToWeth(true, tokenContract, params.amount);

			nativeTokenAmt = params.amount;
		} else {
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
