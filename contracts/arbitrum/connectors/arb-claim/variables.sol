// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interface.sol";

contract Variables {
	IArbitrumTokenDistributor public constant ARBITRUM_TOKEN_DISTRIBUTOR =
		IArbitrumTokenDistributor(0x67a24CE4321aB3aF51c2D0a4801c3E111D88C9d9);

	IArbTokenContract public constant ARB_TOKEN_CONTRACT =
		IArbTokenContract(0x912CE59144191C1204E64559FE8253a0e49E6548);
}
