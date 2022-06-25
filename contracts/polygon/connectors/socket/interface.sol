//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

struct RouteData {
	address route;
	bool isEnabled;
	bool isMiddleware;
}

interface ISocketRegistry {
	function routes(uint256) external view returns (RouteData memory);
}
