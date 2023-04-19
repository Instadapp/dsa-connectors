// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./helpers.sol";
import { Events } from "./events.sol";
import { IArbitrumTokenDistributor } from "./interface.sol";

abstract contract ArbitrumAirdrop is Events, Helpers {

	function claimAirdrop(uint256 setId)
		public
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 claimable = claimableArbTokens(address(this));
		require(claimable > 0, "0-tokens-claimable");
		ARBITRUM_TOKEN_DISTRIBUTOR.claim();
		setUint(setId, claimable);

		eventName_ = "LogArbAirdropClaimed(address,uint256,uint256)";
		eventParam_ = abi.encode(address(this), claimable, setId);
	}

	function delegate(address delegatee)
		public
		returns (string memory eventName_, bytes memory eventParam_)
	{
		ARB_TOKEN_CONTRACT.delegate(delegatee);

		eventName_ = "LogArbTokensDelegated(address,address)";
		eventParam_ = abi.encode(address(this), delegatee);
	}

	function delegateBySig(
		address delegatee,
		uint256 nonce,
		SignedPermits calldata permits
	) public returns (string memory eventName_, bytes memory eventParam_) {
		ARB_TOKEN_CONTRACT.delegateBySig(
			delegatee,
			nonce,
			permits.expiry,
			permits.v,
			permits.r,
			permits.s
		);

		eventName_ = "LogArbTokensDelegatedBySig(address,address,uint256)";
		eventParam_ = abi.encode(address(this), delegatee, nonce);
	}
}

contract ConnectV2ArbitrumAirdrop is ArbitrumAirdrop {
	string public constant name = "ArbitrumAirdrop-v1";
}
