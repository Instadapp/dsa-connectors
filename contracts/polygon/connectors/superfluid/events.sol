//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import { ISuperfluidToken } from "./interface.sol";

contract Events {
	/**
	 * @dev Flow updated event
	 * @param token Super token address
	 * @param sender Flow sender address
	 * @param receiver Flow recipient address
	 * @param flowRate Flow rate in amount per second for this flow
	 * @param totalSenderFlowRate Total flow rate in amount per second for the sender
	 * @param totalReceiverFlowRate Total flow rate in amount per second for the receiver
	 * @param userData The user provided data
	 *
	 */
	event FlowUpdated(
		ISuperfluidToken indexed token,
		address indexed sender,
		address indexed receiver,
		int96 flowRate,
		int256 totalSenderFlowRate,
		int256 totalReceiverFlowRate,
		bytes userData
	);

	/**
	 * @dev Flow operator updated event
	 * @param token Super token address
	 * @param sender Flow sender address
	 * @param flowOperator Flow operator address
	 * @param permissions Octo bitmask representation of permissions
	 * @param flowRateAllowance The flow rate allowance the `flowOperator` is granted (only goes down)
	 */
	event FlowOperatorUpdated(
		ISuperfluidToken indexed token,
		address indexed sender,
		address indexed flowOperator,
		uint8 permissions,
		int96 flowRateAllowance
	);

	/**
	 * @dev Flow updated extension event
	 * @param flowOperator Flow operator address - the Context.msgSender
	 * @param deposit The deposit amount for the stream
	 */
	event FlowUpdatedExtension(address indexed flowOperator, uint256 deposit);

	/**
	 * @dev Index created event
	 * @param token Super token address
	 * @param publisher Index creator and publisher
	 * @param indexId The specified indexId of the newly created index
	 * @param userData The user provided data
	 */
	event IndexCreated(
		ISuperfluidToken indexed token,
		address indexed publisher,
		uint32 indexed indexId,
		bytes userData
	);

	/**
	 * @dev Index updated event
	 * @param token Super token address
	 * @param publisher Index updater and publisher
	 * @param indexId The specified indexId of the updated index
	 * @param oldIndexValue The previous index value
	 * @param newIndexValue The updated index value
	 * @param totalUnitsPending The total units pending when the indexValue was updated
	 * @param totalUnitsApproved The total units approved when the indexValue was updated
	 * @param userData The user provided data
	 */
	event IndexUpdated(
		ISuperfluidToken indexed token,
		address indexed publisher,
		uint32 indexed indexId,
		uint128 oldIndexValue,
		uint128 newIndexValue,
		uint128 totalUnitsPending,
		uint128 totalUnitsApproved,
		bytes userData
	);

	/**
	 * @dev Index subscribed event
	 * @param token Super token address
	 * @param publisher Index publisher
	 * @param indexId The specified indexId
	 * @param subscriber The approved subscriber
	 * @param userData The user provided data
	 */
	event IndexSubscribed(
		ISuperfluidToken indexed token,
		address indexed publisher,
		uint32 indexed indexId,
		address subscriber,
		bytes userData
	);

	/**
	 * @dev Subscription approved event
	 * @param token Super token address
	 * @param subscriber The approved subscriber
	 * @param publisher Index publisher
	 * @param indexId The specified indexId
	 * @param userData The user provided data
	 */
	event SubscriptionApproved(
		ISuperfluidToken indexed token,
		address indexed subscriber,
		address publisher,
		uint32 indexId,
		bytes userData
	);

	/**
	 * @dev Subscription approved event
	 * @param token Super token address
	 * @param subscriber The approved subscriber
	 * @param publisher Index publisher
	 * @param indexId The specified indexId
	 * @param userData The user provided data
	 */
	event SubscriptionRevoked(
		ISuperfluidToken indexed token,
		address indexed subscriber,
		address publisher,
		uint32 indexId,
		bytes userData
	);

	/**
	 * @dev Index units updated event
	 * @param token Super token address
	 * @param publisher Index publisher
	 * @param indexId The specified indexId
	 * @param subscriber The subscriber units updated
	 * @param units The new units amount
	 * @param userData The user provided data
	 */
	event IndexUnitsUpdated(
		ISuperfluidToken indexed token,
		address indexed publisher,
		uint32 indexed indexId,
		address subscriber,
		uint128 units,
		bytes userData
	);

	/**
	 * @dev Subscription units updated event
	 * @param token Super token address
	 * @param subscriber The subscriber units updated
	 * @param indexId The specified indexId
	 * @param publisher Index publisher
	 * @param units The new units amount
	 * @param userData The user provided data
	 */
	event SubscriptionUnitsUpdated(
		ISuperfluidToken indexed token,
		address indexed subscriber,
		address publisher,
		uint32 indexId,
		uint128 units,
		bytes userData
	);

	/**
	 * @dev Index distribution claimed event
	 * @param token Super token address
	 * @param publisher Index publisher
	 * @param indexId The specified indexId
	 * @param subscriber The subscriber units updated
	 * @param amount The pending amount claimed
	 */
	event IndexDistributionClaimed(
		ISuperfluidToken indexed token,
		address indexed publisher,
		uint32 indexed indexId,
		address subscriber,
		uint256 amount
	);

	/**
	 * @dev Subscription distribution claimed event
	 * @param token Super token address
	 * @param subscriber The subscriber units updated
	 * @param publisher Index publisher
	 * @param indexId The specified indexId
	 * @param amount The pending amount claimed
	 */
	event SubscriptionDistributionClaimed(
		ISuperfluidToken indexed token,
		address indexed subscriber,
		address publisher,
		uint32 indexId,
		uint256 amount
	);
}
