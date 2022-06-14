// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

contract Events {
	event SwapAggregator(
		string[] connectors,
		string connectorName,
		string eventName,
		bytes eventParam
	);
}
