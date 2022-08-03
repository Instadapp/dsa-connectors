//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import { ISuperfluidToken } from "./interface.sol";

contract Events {
	event LogWrap(
		address indexed superToken,
		uint256 indexed amount,
		uint256 getId,
		uint256 setId
	);
	event LogUnwrap(
		address indexed superToken,
		uint256 indexed amount,
		uint256 getId,
		uint256 setId
	);
	event LogCreateFlow(
		address indexed receiver,
		address indexed superToken,
		int96 flowRate,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
	event LogUpdateFlow(
		address indexed receiver,
		address indexed superToken,
		int96 flowRate,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
	event LogDeleteFlow(
		address indexed sender,
		address indexed receiver,
		address indexed superToken,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
	event LogAuthorizeFlowOperatorWithFullControl(
		address indexed superToken,
		address indexed flowOperator,
		uint256 getId,
		uint256 setId
	);
	event LogRevokeFlowOperatorWithFullControl(
		address indexed superToken,
		address indexed flowOperator,
		uint256 getId,
		uint256 setId
	);
	event LogUpdateFlowOperatorPermissions(
		address indexed superToken,
		address indexed flowOperator,
		uint8 indexed permissions,
		int96 flowRateAllowance,
		uint256 getId,
		uint256 setId
	);
	event LogCreateFlowByOperator(
		address indexed superToken,
		address indexed sender,
		address indexed receiver,
		int96 flowRate,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
	event LogUpdateFlowByOperator(
		address indexed superToken,
		address indexed sender,
		address indexed receiver,
		int96 flowRate,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
	event LogDeleteFlowByOperator(
		address indexed superToken,
		address indexed sender,
		address indexed receiver,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
	event LogCreateIndex(
		address indexed superToken,
		uint32 indexed indexId,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
	event LogUpdateIndexValue(
		address indexed superToken,
		uint32 indexed id,
		uint128 indexValue,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
	event LogDistribute(
		address indexed superToken,
		uint32 indexed id,
		uint256 amount,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
	event LogApproveSubscription(
		address indexed superToken,
		address indexed publisher,
		uint32 indexed indexId,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
	event LogRevokeSubscription(
		address indexed superToken,
		address indexed publisher,
		uint32 indexed indexId,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
	event LogUpdateSubscriptionUnits(
		address indexed superToken,
		uint32 indexed indexId,
		address indexed subscriber,
		uint128 units,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
	event LogDeleteSubscription(
		address indexed superToken,
		address indexed publisher,
		uint32 indexed indexId,
		address subscriber,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
	event LogClaim(
		address indexed superToken,
		address indexed publisher,
		uint32 indexed indexId,
		address subscriber,
		bytes userData,
		uint256 getId,
		uint256 setId
	);
}
