//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISuperToken } from "./interface.sol";
import { CFAv1Library } from "./libraries/CFAv1Library.sol";
import { IDAv1Library } from "./libraries/IDAv1Library.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract Superfluid is Helpers, Events {
	/**
	 * @dev Wrap
	 * @notice Convert ERC20 tokens to wrapped super tokens of Superfluid Protocol.
	 * @param superToken The super token contract which is being used for the wrapping
	 * @param amount Number of underlying tokens to be wrapped (denominated in wei)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function wrap(
		ISuperToken superToken,
		uint256 amount,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		IERC20(superToken.getUnderlyingToken()).approve(
			address(superToken),
			amount
		);
		superToken.upgrade(amount);
	}

	/**
	 * @dev Unwrap
	 * @notice Convert wrapped super tokens to their underlying ERC20 asset.
	 * @param superToken The super token contract which is being unwrapped
	 * @param amount Number of underlying tokens to be unwrapped (denominated in wei)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function unwrap(
		ISuperToken superToken,
		uint256 amount,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		superToken.downgrade(amount);
	}

	/**
	 * @title CFA Operations
	 */

	/**
	 * @dev Create Flow
	 * @notice Create a stream of superToken to a receiver at flowRate.
	 * @param receiver The receiver of the stream
	 * @param superToken The super token which will be streamed to the receiver
	 * @param flowRate Number of tokens sent to the receiver per second (denominated in wei)
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function createFlow(
		address receiver,
		ISuperToken superToken,
		int96 flowRate,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		CFAv1Library.createFlow(
			cfaV1,
			receiver,
			superToken,
			flowRate,
			userData
		);
	}

	/**
	 * @dev Update Flow
	 * @notice Update the flow rate of the stream.
	 * @param receiver The receiver of the stream
	 * @param superToken The super token which will be streamed to the receiver
	 * @param flowRate Number of tokens sent to the receiver per second (denominated in wei)
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function updateFlow(
		address receiver,
		ISuperToken superToken,
		int96 flowRate,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		CFAv1Library.updateFlow(
			cfaV1,
			receiver,
			superToken,
			flowRate,
			userData
		);
	}

	/**
	 * @dev Delete Flow
	 * @notice Delete an existing stream.
	 * @param sender The sender of the stream
	 * @param receiver The receiver of the stream
	 * @param superToken The super token which will be streamed to the receiver
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function deleteFlow(
		address sender,
		address receiver,
		ISuperToken superToken,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		CFAv1Library.deleteFlow(cfaV1, sender, receiver, superToken, userData);
	}

	/**
	 * @title CFA - Access Control List Operations
	 */

	/**
	 * @dev Authorize Flow Operator with Full Control
	 * @notice Grant full access over streams to an operator.
	 * @param superToken The super token on which the flowOperator is receiving approval
	 * @param flowOperator The operator being granted full permissions on the token for the msg.sender on this function call
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function authorizeFlowOperatorWithFullControl(
		ISuperToken superToken,
		address flowOperator,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		CFAv1Library.authorizeFlowOperatorWithFullControl(
			cfaV1,
			flowOperator,
			superToken
		);
	}

	/**
	 * @dev Revoke Flow Operator with Full Control
	 * @notice Remove all access to stream operation from operator.
	 * @param superToken The super token on which the flowOperator is being revoked
	 * @param flowOperator The operator who is getting permissions revoked on the token for the msg.sender on this function call
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function revokeFlowOperatorWithFullControl(
		ISuperToken superToken,
		address flowOperator,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		CFAv1Library.revokeFlowOperatorWithFullControl(
			cfaV1,
			flowOperator,
			superToken
		);
	}

	/**
	 * @dev Update Flow Operator Permissions
	 * @notice Set granular permissions for operators over streams.
	 * @param superToken The super token on which the flowOperator is being updated
	 * @param flowOperator The operator who is getting permissions updated on the token for the msg.sender on this function call
	 * @param permissions The permission level (1-7) that the flowOperator will receive
	 * @param flowRateAllowance The flow rate allowance that the operator will be receiving
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function updateFlowOperatorPermissions(
		ISuperToken superToken,
		address flowOperator,
		uint8 permissions,
		int96 flowRateAllowance,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		CFAv1Library.updateFlowOperatorPermissions(
			cfaV1,
			flowOperator,
			superToken,
			permissions,
			flowRateAllowance
		);
	}

	/**
	 * @dev Create Flow by Operator
	 * @notice Create a flow between sender and receiver.
	 * @param superToken The super token on which the flow is being created by operator
	 * @param sender The sender on the flow
	 * @param receiver The receiver of the flow
	 * @param flowRate Number of tokens sent to the receiver per second (denominated in wei)
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function createFlowByOperator(
		ISuperToken superToken,
		address sender,
		address receiver,
		int96 flowRate,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		CFAv1Library.createFlowByOperator(
			cfaV1,
			sender,
			receiver,
			superToken,
			flowRate,
			userData
		);
	}

	/**
	 * @dev Update Flow by Operator
	 * @notice Update a flow between sender and receiver.
	 * @param superToken The super token on which the flow is being updated by operator
	 * @param sender The sender on the flow
	 * @param receiver The receiver of the flow
	 * @param flowRate Number of tokens sent to the receiver per second (denominated in wei)
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function updateFlowByOperator(
		ISuperToken superToken,
		address sender,
		address receiver,
		int96 flowRate,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		CFAv1Library.updateFlowByOperator(
			cfaV1,
			sender,
			receiver,
			superToken,
			flowRate,
			userData
		);
	}

	/**
	 * @dev Delete Flow by Operator
	 * @notice Delete the flow between sender and receiver.
	 * @param superToken The super token on which the flow is being deleted by operator
	 * @param sender The sender on the flow
	 * @param receiver The receiver of the flow
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function deleteFlowByOperator(
		ISuperToken superToken,
		address sender,
		address receiver,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		CFAv1Library.deleteFlowByOperator(
			cfaV1,
			sender,
			receiver,
			superToken,
			userData
		);
	}

	/**
	 * @title IDA Operations
	 */

	/**
	 * @dev Create Index
	 * @notice Creates an index with a super token and an index id.
	 * @param superToken The super token which will be used within the index
	 * @param indexId The id on the index which will be used as an identifier
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function createIndex(
		ISuperToken superToken,
		uint32 indexId,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		IDAv1Library.createIndex(_idav1Lib, superToken, indexId, userData);
	}

	/**
	 * @dev Update Index Value
	 * @notice Updates the value of the index.
	 * @param superToken The super token which will be used within the index
	 * @param id The identifier of the index
	 * @param indexValue uint128
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function updateIndexValue(
		ISuperToken superToken,
		uint32 id,
		uint128 indexValue,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		IDAv1Library.updateIndexValue(
			_idav1Lib,
			superToken,
			id,
			indexValue,
			userData
		);
	}

	/**
	 * @dev Distribute
	 * @notice Distribute tokens to subscribers.
	 * @param superToken The super token which will be used within the index
	 * @param id The identifier of the index
	 * @param amount The amount to distribute to the subscribers within the index
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function distribute(
		ISuperToken superToken,
		uint32 id,
		uint256 amount,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		IDAv1Library.distribute(_idav1Lib, superToken, id, amount, userData);
	}

	/**
	 * @dev Approve Subscription
	 * @notice Approves a subscription to an index.
	 * @param superToken The super token which is used within the index
	 * @param publisher The creator of the index
	 * @param indexId The identifier of the index
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function approveSubscription(
		ISuperToken superToken,
		address publisher,
		uint32 indexId,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		IDAv1Library.approveSubscription(
			_idav1Lib,
			superToken,
			publisher,
			indexId,
			userData
		);
	}

	/**
	 * @dev Revoke Subscription
	 * @notice Revokes a previously approved subscription.
	 * @param superToken The super token which is used within the index
	 * @param publisher The creator of the index
	 * @param indexId The identifier of the index
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function revokeSubscription(
		ISuperToken superToken,
		address publisher,
		uint32 indexId,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		IDAv1Library.revokeSubscription(
			_idav1Lib,
			superToken,
			publisher,
			indexId,
			userData
		);
	}

	/**
	 * @dev Update Subscription Units
	 * @notice Updates the number of units, or "shares", of the index assigned to a subscriber
	 * @param superToken The super token which is used within the index
	 * @param indexId The identifier of the index
	 * @param subscriber The subscriber which is having its units updated
	 * @param units The updated number of units that the subscriber will receive
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function updateSubscriptionUnits(
		ISuperToken superToken,
		uint32 indexId,
		address subscriber,
		uint128 units,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		IDAv1Library.updateSubscriptionUnits(
			_idav1Lib,
			superToken,
			indexId,
			subscriber,
			units,
			userData
		);
	}

	/**
	 * @dev Delete Subscription
	 * @notice Deletes an existing subscription, setting the subscriber's units to zero.
	 * @param superToken The super token which is used within the index
	 * @param publisher The creator of the index
	 * @param indexId The identifier of the index
	 * @param subscriber The subscriber which is having its subscription deleted
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function deleteSubscription(
		ISuperToken superToken,
		address publisher,
		uint32 indexId,
		address subscriber,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		IDAv1Library.deleteSubscription(
			_idav1Lib,
			superToken,
			publisher,
			indexId,
			subscriber,
			userData
		);
	}

	/**
	 * @dev Claim
	 * @notice Claims a pendind distribution of an index.
	 * @param superToken The super token which is used within the index
	 * @param publisher The creator of the index
	 * @param indexId The identifier of the index
	 * @param subscriber The subscriber who is claiming the pending distribution of the index
	 * @param userData Optional bytes value for passing in arbitrary data along with the transaction.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of token.
	 */
	function claim(
		ISuperToken superToken,
		address publisher,
		uint32 indexId,
		address subscriber,
		bytes calldata userData,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		IDAv1Library.claim(
			_idav1Lib,
			superToken,
			publisher,
			indexId,
			subscriber,
			userData
		);
	}
}
