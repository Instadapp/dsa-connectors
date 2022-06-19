// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

contract Events {
	event LogCastDSA(
        address indexed targetDSA,
		string[] connectors,
		bytes[] datas
	);
}
