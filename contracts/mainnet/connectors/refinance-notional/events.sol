//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { TokenInterface } from "./interface.sol";

contract Events {
	event LogRefinance(
		uint256 indexed source,
		uint256 indexed target,
		uint256 collateralFee,
		uint256 debtFee,
		address[] tokens,
		uint256[] borrowAmts,
		uint256[] depositAmts,
		uint256[] borrowMarketIndices,
		uint256[] maxBorrowingRates
	);
}
