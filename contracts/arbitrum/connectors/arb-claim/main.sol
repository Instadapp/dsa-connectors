// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./helpers.sol";
import { Events } from "./events.sol";
import { IArbitrumTokenDistributor } from "./interface.sol";

abstract contract ArbitrumAirdrop is Events, Helpers {

    /**
	 * @dev DSA Arbitrum airdrop claim function.
	 * @param setId ID to set the claimable amount in the DSA
	 */
	function claimAirdrop(uint256 setId)
		public
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 claimable = claimableArbTokens(address(this));

		// If claimable <= 0, ARB TokenDistributor will revert on claim.
		ARBITRUM_TOKEN_DISTRIBUTOR.claim();
		setUint(setId, claimable);

		eventName_ = "LogArbAirdropClaimed(address,uint256,uint256)";
		eventParam_ = abi.encode(address(this), claimable, setId);
	}

    /**
	 * @dev Delegates votes from signer to `delegatee`.
	 * @param delegatee The address to delegate the ARB tokens to.
	 */
	function delegate(address delegatee)
		public
		returns (string memory eventName_, bytes memory eventParam_)
	{
		ARB_TOKEN_CONTRACT.delegate(delegatee);

		eventName_ = "LogArbTokensDelegated(address,address)";
		eventParam_ = abi.encode(address(this), delegatee);
	}
}

contract ConnectV2ArbitrumAirdrop is ArbitrumAirdrop {
	string public constant name = "ArbitrumAirdrop-v1";
}
