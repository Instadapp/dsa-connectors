// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	using SafeERC20 for IERC20;

	IProtocolModule internal constant protocolModule =
		IProtocolModule(0xf40c01Adc86CF5d534Ff5CaFaA451694FdD2b08C);

	function approve(
		TokenInterface token_,
		address spender_,
		uint256 amount_
	) internal {
		try token_.approve(spender_, amount_) {} catch {
			IERC20 tokenContract_ = IERC20(address(token_));
			tokenContract_.safeApprove(spender_, 0);
			tokenContract_.safeApprove(spender_, amount_);
		}
	}
}
