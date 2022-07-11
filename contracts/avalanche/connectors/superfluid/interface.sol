// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { IERC777 } from "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BatchOperation, ContextDefinitions, FlowOperatorDefinitions, SuperAppDefinitions, SuperfluidGovernanceConfigs } from "./libraries/Definitions.sol";

/**
 * @title ERC20 token info interface
 * @author Superfluid
 * @dev ERC20 standard interface does not specify these functions, but
 *      often the token implementations have them.
 */
interface TokenInfo {
	/**
	 * @dev Returns the name of the token.
	 */
	function name() external view returns (string memory);

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
	 * called.
	 *
	 * NOTE: This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IERC20-balanceOf} and {IERC20-transfer}.
	 */
	function decimals() external view returns (uint8);
}

/**
 * @title ERC20 token with token info interface
 * @author Superfluid
 * @dev Using abstract contract instead of interfaces because old solidity
 *      does not support interface inheriting other interfaces
 * solhint-disable-next-line no-empty-blocks
 *
 */
// solhint-disable-next-line no-empty-blocks
abstract contract ERC20WithTokenInfo is IERC20, TokenInfo {

}

/**
 * @title Superfluid token interface
 * @author Superfluid
 */
interface ISuperfluidToken {
	/**************************************************************************
	 * Basic information
	 *************************************************************************/

	/**
	 * @dev Get superfluid host contract address
	 */
	function getHost() external view returns (address host);

	/**
	 * @dev Encoded liquidation type data mainly used for handling stack to deep errors
	 *
	 * - version: 1
	 * - liquidationType key:
	 *    - 0 = reward account receives reward (PIC period)
	 *    - 1 = liquidator account receives reward (Pleb period)
	 *    - 2 = liquidator account receives reward (Pirate period/bailout)
	 */
	struct LiquidationTypeData {
		uint256 version;
		uint8 liquidationType;
	}

	/**************************************************************************
	 * Real-time balance functions
	 *************************************************************************/

	/**
	 * @dev Calculate the real balance of a user, taking in consideration all agreements of the account
	 * @param account for the query
	 * @param timestamp Time of balance
	 * @return availableBalance Real-time balance
	 * @return deposit Account deposit
	 * @return owedDeposit Account owed Deposit
	 */
	function realtimeBalanceOf(address account, uint256 timestamp)
		external
		view
		returns (
			int256 availableBalance,
			uint256 deposit,
			uint256 owedDeposit
		);

	/**
	 * @notice Calculate the realtime balance given the current host.getNow() value
	 * @dev realtimeBalanceOf with timestamp equals to block timestamp
	 * @param account for the query
	 * @return availableBalance Real-time balance
	 * @return deposit Account deposit
	 * @return owedDeposit Account owed Deposit
	 */
	function realtimeBalanceOfNow(address account)
		external
		view
		returns (
			int256 availableBalance,
			uint256 deposit,
			uint256 owedDeposit,
			uint256 timestamp
		);

	/**
	 * @notice Check if account is critical
	 * @dev A critical account is when availableBalance < 0
	 * @param account The account to check
	 * @param timestamp The time we'd like to check if the account is critical (should use future)
	 * @return isCritical Whether the account is critical
	 */
	function isAccountCritical(address account, uint256 timestamp)
		external
		view
		returns (bool isCritical);

	/**
	 * @notice Check if account is critical now (current host.getNow())
	 * @dev A critical account is when availableBalance < 0
	 * @param account The account to check
	 * @return isCritical Whether the account is critical
	 */
	function isAccountCriticalNow(address account)
		external
		view
		returns (bool isCritical);

	/**
	 * @notice Check if account is solvent
	 * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
	 * @param account The account to check
	 * @param timestamp The time we'd like to check if the account is solvent (should use future)
	 * @return isSolvent True if the account is solvent, false otherwise
	 */
	function isAccountSolvent(address account, uint256 timestamp)
		external
		view
		returns (bool isSolvent);

	/**
	 * @notice Check if account is solvent now
	 * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
	 * @param account The account to check
	 * @return isSolvent True if the account is solvent, false otherwise
	 */
	function isAccountSolventNow(address account)
		external
		view
		returns (bool isSolvent);

	/**
	 * @notice Get a list of agreements that is active for the account
	 * @dev An active agreement is one that has state for the account
	 * @param account Account to query
	 * @return activeAgreements List of accounts that have non-zero states for the account
	 */
	function getAccountActiveAgreements(address account)
		external
		view
		returns (ISuperAgreement[] memory activeAgreements);

	/**************************************************************************
	 * Super Agreement hosting functions
	 *************************************************************************/

	/**
	 * @dev Create a new agreement
	 * @param id Agreement ID
	 * @param data Agreement data
	 */
	function createAgreement(bytes32 id, bytes32[] calldata data) external;

	/**
	 * @dev Agreement created event
	 * @param agreementClass Contract address of the agreement
	 * @param id Agreement ID
	 * @param data Agreement data
	 */
	event AgreementCreated(
		address indexed agreementClass,
		bytes32 id,
		bytes32[] data
	);

	/**
	 * @dev Get data of the agreement
	 * @param agreementClass Contract address of the agreement
	 * @param id Agreement ID
	 * @return data Data of the agreement
	 */
	function getAgreementData(
		address agreementClass,
		bytes32 id,
		uint256 dataLength
	) external view returns (bytes32[] memory data);

	/**
	 * @dev Create a new agreement
	 * @param id Agreement ID
	 * @param data Agreement data
	 */
	function updateAgreementData(bytes32 id, bytes32[] calldata data) external;

	/**
	 * @dev Agreement updated event
	 * @param agreementClass Contract address of the agreement
	 * @param id Agreement ID
	 * @param data Agreement data
	 */
	event AgreementUpdated(
		address indexed agreementClass,
		bytes32 id,
		bytes32[] data
	);

	/**
	 * @dev Close the agreement
	 * @param id Agreement ID
	 */
	function terminateAgreement(bytes32 id, uint256 dataLength) external;

	/**
	 * @dev Agreement terminated event
	 * @param agreementClass Contract address of the agreement
	 * @param id Agreement ID
	 */
	event AgreementTerminated(address indexed agreementClass, bytes32 id);

	/**
	 * @dev Update agreement state slot
	 * @param account Account to be updated
	 *
	 * - To clear the storage out, provide zero-ed array of intended length
	 */
	function updateAgreementStateSlot(
		address account,
		uint256 slotId,
		bytes32[] calldata slotData
	) external;

	/**
	 * @dev Agreement account state updated event
	 * @param agreementClass Contract address of the agreement
	 * @param account Account updated
	 * @param slotId slot id of the agreement state
	 */
	event AgreementStateUpdated(
		address indexed agreementClass,
		address indexed account,
		uint256 slotId
	);

	/**
	 * @dev Get data of the slot of the state of an agreement
	 * @param agreementClass Contract address of the agreement
	 * @param account Account to query
	 * @param slotId slot id of the state
	 * @param dataLength length of the state data
	 */
	function getAgreementStateSlot(
		address agreementClass,
		address account,
		uint256 slotId,
		uint256 dataLength
	) external view returns (bytes32[] memory slotData);

	/**
	 * @notice Settle balance from an account by the agreement
	 * @dev The agreement needs to make sure that the balance delta is balanced afterwards
	 * @param account Account to query.
	 * @param delta Amount of balance delta to be settled
	 *
	 *  - onlyAgreement
	 */
	function settleBalance(address account, int256 delta) external;

	/**
	 * @dev Make liquidation payouts (v2)
	 * @param id Agreement ID
	 * @param liquidationTypeData Data regarding the version of the liquidation schema and the type
	 * @param liquidatorAccount Address of the executor of the liquidation
	 * @param useDefaultRewardAccount Whether or not the default reward account receives the rewardAmount
	 * @param targetAccount Account to be liquidated
	 * @param rewardAmount The amount the rewarded account will receive
	 * @param targetAccountBalanceDelta The delta amount the target account balance should change by
	 *
	 * - If a bailout is required (bailoutAmount > 0)
	 *   - the actual reward (single deposit) goes to the executor,
	 *   - while the reward account becomes the bailout account
	 *   - total bailout include: bailout amount + reward amount
	 *   - the targetAccount will be bailed out
	 * - If a bailout is not required
	 *   - the targetAccount will pay the rewardAmount
	 *   - the liquidator (reward account in PIC period) will receive the rewardAmount
	 *
	 *  - onlyAgreement
	 */
	function makeLiquidationPayoutsV2(
		bytes32 id,
		bytes memory liquidationTypeData,
		address liquidatorAccount,
		bool useDefaultRewardAccount,
		address targetAccount,
		uint256 rewardAmount,
		int256 targetAccountBalanceDelta
	) external;

	/**
	 * @dev Agreement liquidation event v2 (including agent account)
	 * @param agreementClass Contract address of the agreement
	 * @param id Agreement ID
	 * @param liquidatorAccount Address of the executor of the liquidation
	 * @param targetAccount Account of the stream sender
	 * @param rewardAmountReceiver Account that collects the reward or bails out insolvent accounts
	 * @param rewardAmount The amount the reward recipient account balance should change by
	 * @param targetAccountBalanceDelta The amount the sender account balance should change by
	 * @param liquidationTypeData The encoded liquidation type data including the version (how to decode)
	 *
	 * Reward account rule:
	 * - if the agreement is liquidated during the PIC period
	 *   - the rewardAmountReceiver will get the rewardAmount (remaining deposit), regardless of the liquidatorAccount
	 *   - the targetAccount will pay for the rewardAmount
	 * - if the agreement is liquidated after the PIC period AND the targetAccount is solvent
	 *   - the rewardAmountReceiver will get the rewardAmount (remaining deposit)
	 *   - the targetAccount will pay for the rewardAmount
	 * - if the targetAccount is insolvent
	 *   - the liquidatorAccount will get the rewardAmount (single deposit)
	 *   - the default reward account (governance) will pay for both the rewardAmount and bailoutAmount
	 *   - the targetAccount will receive the bailoutAmount
	 */
	event AgreementLiquidatedV2(
		address indexed agreementClass,
		bytes32 id,
		address indexed liquidatorAccount,
		address indexed targetAccount,
		address rewardAmountReceiver,
		uint256 rewardAmount,
		int256 targetAccountBalanceDelta,
		bytes liquidationTypeData
	);

	/**************************************************************************
	 * Function modifiers for access control and parameter validations
	 *
	 * While they cannot be explicitly stated in function definitions, they are
	 * listed in function definition comments instead for clarity.
	 *
	 * NOTE: solidity-coverage not supporting it
	 *************************************************************************/

	/// @dev The msg.sender must be host contract
	//modifier onlyHost() virtual;

	/// @dev The msg.sender must be a listed agreement.
	//modifier onlyAgreement() virtual;

	/**************************************************************************
	 * DEPRECATED
	 *************************************************************************/

	/**
	 * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedBy)
	 * @param agreementClass Contract address of the agreement
	 * @param id Agreement ID
	 * @param penaltyAccount Account of the agreement to be penalized
	 * @param rewardAccount Account that collect the reward
	 * @param rewardAmount Amount of liquidation reward
	 */
	event AgreementLiquidated(
		address indexed agreementClass,
		bytes32 id,
		address indexed penaltyAccount,
		address indexed rewardAccount,
		uint256 rewardAmount
	);

	/**
	 * @dev System bailout occurred (DEPRECATED BY AgreementLiquidatedBy)
	 * @param bailoutAccount Account that bailout the penalty account
	 * @param bailoutAmount Amount of account bailout
	 */
	event Bailout(address indexed bailoutAccount, uint256 bailoutAmount);

	/**
	 * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedV2)
	 * @param liquidatorAccount Account of the agent that performed the liquidation.
	 * @param agreementClass Contract address of the agreement
	 * @param id Agreement ID
	 * @param penaltyAccount Account of the agreement to be penalized
	 * @param bondAccount Account that collect the reward or bailout accounts
	 * @param rewardAmount Amount of liquidation reward
	 * @param bailoutAmount Amount of liquidation bailouot
	 *
	 * Reward account rule:
	 * - if bailout is equal to 0, then
	 *   - the bondAccount will get the rewardAmount,
	 *   - the penaltyAccount will pay for the rewardAmount.
	 * - if bailout is larger than 0, then
	 *   - the liquidatorAccount will get the rewardAmouont,
	 *   - the bondAccount will pay for both the rewardAmount and bailoutAmount,
	 *   - the penaltyAccount will pay for the rewardAmount while get the bailoutAmount.
	 */
	event AgreementLiquidatedBy(
		address liquidatorAccount,
		address indexed agreementClass,
		bytes32 id,
		address indexed penaltyAccount,
		address indexed bondAccount,
		uint256 rewardAmount,
		uint256 bailoutAmount
	);
}

/**
 * @title Super token (Superfluid Token + ERC20 + ERC777) interface
 * @author Superfluid
 */
interface ISuperToken is ISuperfluidToken, TokenInfo, IERC20, IERC777 {
	/**
	 * @dev Initialize the contract
	 */
	function initialize(
		IERC20 underlyingToken,
		uint8 underlyingDecimals,
		string calldata n,
		string calldata s
	) external;

	/**************************************************************************
	 * TokenInfo & ERC777
	 *************************************************************************/

	/**
	 * @dev Returns the name of the token.
	 */
	function name()
		external
		view
		override(IERC777, TokenInfo)
		returns (string memory);

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function symbol()
		external
		view
		override(IERC777, TokenInfo)
		returns (string memory);

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
	 * called.
	 *
	 * This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IERC20-balanceOf} and {IERC20-transfer}.
	 */
	function decimals() external view override(TokenInfo) returns (uint8);

	/**************************************************************************
	 * ERC20 & ERC777
	 *************************************************************************/

	/**
	 * @dev See {IERC20-totalSupply}.
	 */
	function totalSupply()
		external
		view
		override(IERC777, IERC20)
		returns (uint256);

	/**
	 * @dev Returns the amount of tokens owned by an account (`owner`).
	 */
	function balanceOf(address account)
		external
		view
		override(IERC777, IERC20)
		returns (uint256 balance);

	/**************************************************************************
	 * ERC20
	 *************************************************************************/

	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * @return Returns Success a boolean value indicating whether the operation succeeded.
	 */
	function transfer(address recipient, uint256 amount)
		external
		override(IERC20)
		returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 *         allowed to spend on behalf of `owner` through {transferFrom}. This is
	 *         zero by default.
	 *
	 * @notice This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender)
		external
		view
		override(IERC20)
		returns (uint256);

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
	 *
	 * @return Returns Success a boolean value indicating whether the operation succeeded.
	 *
	 * Beware that changing an allowance with this method brings the risk
	 * that someone may use both the old and the new allowance by unfortunate
	 * transaction ordering. One possible solution to mitigate this race
	 * condition is to first reduce the spender's allowance to 0 and set the
	 * desired value afterwards:
	 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	 *
	 */
	function approve(address spender, uint256 amount)
		external
		override(IERC20)
		returns (bool);

	/**
	 * @dev Moves `amount` tokens from `sender` to `recipient` using the
	 *         allowance mechanism. `amount` is then deducted from the caller's
	 *         allowance.
	 *
	 * @return Returns Success a boolean value indicating whether the operation succeeded.
	 *
	 */
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external override(IERC20) returns (bool);

	/**
	 * @dev Atomically increases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {IERC20-approve}.
	 *
	 * - `spender` cannot be the zero address.
	 */
	function increaseAllowance(address spender, uint256 addedValue)
		external
		returns (bool);

	/**
	 * @dev Atomically decreases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {IERC20-approve}.
	 *
	 * - `spender` cannot be the zero address.
	 * - `spender` must have allowance for the caller of at least
	 * `subtractedValue`.
	 */
	function decreaseAllowance(address spender, uint256 subtractedValue)
		external
		returns (bool);

	/**************************************************************************
	 * ERC777
	 *************************************************************************/

	/**
	 * @dev Returns the smallest part of the token that is not divisible. This
	 *         means all token operations (creation, movement and destruction) must have
	 *         amounts that are a multiple of this number.
	 */
	function granularity() external view override(IERC777) returns (uint256);

	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * @dev If send or receive hooks are registered for the caller and `recipient`,
	 *      the corresponding functions will be called with `data` and empty
	 *      `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
	 *
	 * - the caller must have at least `amount` tokens.
	 * - `recipient` cannot be the zero address.
	 * - if `recipient` is a contract, it must implement the {IERC777Recipient}
	 * interface.
	 */
	function send(
		address recipient,
		uint256 amount,
		bytes calldata data
	) external override(IERC777);

	/**
	 * @dev Destroys `amount` tokens from the caller's account, reducing the
	 * total supply.
	 *
	 * If a send hook is registered for the caller, the corresponding function
	 * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
	 *
	 * - the caller must have at least `amount` tokens.
	 */
	function burn(uint256 amount, bytes calldata data)
		external
		override(IERC777);

	/**
	 * @dev Returns true if an account is an operator of `tokenHolder`.
	 * Operators can send and burn tokens on behalf of their owners. All
	 * accounts are their own operator.
	 *
	 * See {operatorSend} and {operatorBurn}.
	 */
	function isOperatorFor(address operator, address tokenHolder)
		external
		view
		override(IERC777)
		returns (bool);

	/**
	 * @dev Make an account an operator of the caller.
	 *
	 * See {isOperatorFor}.
	 *
	 * - `operator` cannot be calling address.
	 */
	function authorizeOperator(address operator) external override(IERC777);

	/**
	 * @dev Revoke an account's operator status for the caller.
	 *
	 * See {isOperatorFor} and {defaultOperators}.
	 *
	 * - `operator` cannot be calling address.
	 */
	function revokeOperator(address operator) external override(IERC777);

	/**
	 * @dev Returns the list of default operators. These accounts are operators
	 * for all token holders, even if {authorizeOperator} was never called on
	 * them.
	 *
	 * This list is immutable, but individual holders may revoke these via
	 * {revokeOperator}, in which case {isOperatorFor} will return false.
	 */
	function defaultOperators()
		external
		view
		override(IERC777)
		returns (address[] memory);

	/**
	 * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
	 * be an operator of `sender`.
	 *
	 * If send or receive hooks are registered for `sender` and `recipient`,
	 * the corresponding functions will be called with `data` and
	 * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
	 *
	 * - `sender` cannot be the zero address.
	 * - `sender` must have at least `amount` tokens.
	 * - the caller must be an operator for `sender`.
	 * - `recipient` cannot be the zero address.
	 * - if `recipient` is a contract, it must implement the {IERC777Recipient}
	 * interface.
	 */
	function operatorSend(
		address sender,
		address recipient,
		uint256 amount,
		bytes calldata data,
		bytes calldata operatorData
	) external override(IERC777);

	/**
	 * @dev Destroys `amount` tokens from `account`, reducing the total supply.
	 * The caller must be an operator of `account`.
	 *
	 * If a send hook is registered for `account`, the corresponding function
	 * will be called with `data` and `operatorData`. See {IERC777Sender}.
	 *
	 * - `account` cannot be the zero address.
	 * - `account` must have at least `amount` tokens.
	 * - the caller must be an operator for `account`.
	 */
	function operatorBurn(
		address account,
		uint256 amount,
		bytes calldata data,
		bytes calldata operatorData
	) external override(IERC777);

	/**************************************************************************
	 * SuperToken custom token functions
	 *************************************************************************/

	/**
	 * @dev Mint new tokens for the account
	 *
	 *  - onlySelf
	 */
	function selfMint(
		address account,
		uint256 amount,
		bytes memory userData
	) external;

	/**
	 * @dev Burn existing tokens for the account
	 *
	 *  - onlySelf
	 */
	function selfBurn(
		address account,
		uint256 amount,
		bytes memory userData
	) external;

	/**
	 * @dev Transfer `amount` tokens from the `sender` to `recipient`.
	 * If `spender` isn't the same as `sender`, checks if `spender` has allowance to
	 * spend tokens of `sender`.
	 *
	 *  - onlySelf
	 */
	function selfTransferFrom(
		address sender,
		address spender,
		address recipient,
		uint256 amount
	) external;

	/**
	 * @dev Give `spender`, `amount` allowance to spend the tokens of
	 * `account`.
	 *
	 *  - onlySelf
	 */
	function selfApproveFor(
		address account,
		address spender,
		uint256 amount
	) external;

	/**************************************************************************
	 * SuperToken extra functions
	 *************************************************************************/

	/**
	 * @dev Transfer all available balance from `msg.sender` to `recipient`
	 */
	function transferAll(address recipient) external;

	/**************************************************************************
	 * ERC20 wrapping
	 *************************************************************************/

	/**
	 * @dev Return the underlying token contract
	 * @return tokenAddr Underlying token address
	 */
	function getUnderlyingToken() external view returns (address tokenAddr);

	/**
	 * @dev Upgrade ERC20 to SuperToken.
	 * @param amount Number of tokens to be upgraded (in 18 decimals)
	 *
	 * It will use `transferFrom` to get tokens. Before calling this
	 * function you should `approve` this contract
	 */
	function upgrade(uint256 amount) external;

	/**
	 * @dev Upgrade ERC20 to SuperToken and transfer immediately
	 * @param to The account to received upgraded tokens
	 * @param amount Number of tokens to be upgraded (in 18 decimals)
	 * @param data User data for the TokensRecipient callback
	 *
	 * It will use `transferFrom` to get tokens. Before calling this
	 * function you should `approve` this contract
	 */
	function upgradeTo(
		address to,
		uint256 amount,
		bytes calldata data
	) external;

	/**
	 * @dev Token upgrade event
	 * @param account Account where tokens are upgraded to
	 * @param amount Amount of tokens upgraded (in 18 decimals)
	 */
	event TokenUpgraded(address indexed account, uint256 amount);

	/**
	 * @dev Downgrade SuperToken to ERC20.
	 * @dev It will call transfer to send tokens
	 * @param amount Number of tokens to be downgraded
	 */
	function downgrade(uint256 amount) external;

	/**
	 * @dev Token downgrade event
	 * @param account Account whose tokens are upgraded
	 * @param amount Amount of tokens downgraded
	 */
	event TokenDowngraded(address indexed account, uint256 amount);

	/**************************************************************************
	 * Batch Operations
	 *************************************************************************/

	/**
	 * @dev Perform ERC20 approve by host contract.
	 * @param account The account owner to be approved.
	 * @param spender The spender of account owner's funds.
	 * @param amount Number of tokens to be approved.
	 *
	 *  - onlyHost
	 */
	function operationApprove(
		address account,
		address spender,
		uint256 amount
	) external;

	/**
	 * @dev Perform ERC20 transfer from by host contract.
	 * @param account The account to spend sender's funds.
	 * @param spender  The account where the funds is sent from.
	 * @param recipient The recipient of thefunds.
	 * @param amount Number of tokens to be transferred.
	 *
	 *  - onlyHost
	 */
	function operationTransferFrom(
		address account,
		address spender,
		address recipient,
		uint256 amount
	) external;

	/**
	 * @dev Upgrade ERC20 to SuperToken by host contract.
	 * @param account The account to be changed.
	 * @param amount Number of tokens to be upgraded (in 18 decimals)
	 *
	 *  - onlyHost
	 */
	function operationUpgrade(address account, uint256 amount) external;

	/**
	 * @dev Downgrade ERC20 to SuperToken by host contract.
	 * @param account The account to be changed.
	 * @param amount Number of tokens to be downgraded (in 18 decimals)
	 *
	 *  - onlyHost
	 */
	function operationDowngrade(address account, uint256 amount) external;

	/**************************************************************************
	 * Function modifiers for access control and parameter validations
	 *
	 * While they cannot be explicitly stated in function definitions, they are
	 * listed in function definition comments instead for clarity.
	 *
	 * NOTE: solidity-coverage not supporting it
	 *************************************************************************/

	/// @dev The msg.sender must be the contract itself
	//modifier onlySelf() virtual
}

/**
 * @title Super token factory interface
 * @author Superfluid
 */
interface ISuperTokenFactory {
	/**
	 * @dev Get superfluid host contract address
	 */
	function getHost() external view returns (address host);

	/// @dev Initialize the contract
	function initialize() external;

	/**
	 * @dev Get the current super token logic used by the factory
	 */
	function getSuperTokenLogic()
		external
		view
		returns (ISuperToken superToken);

	/**
	 * @dev Upgradability modes
	 */
	enum Upgradability {
		/// Non upgradable super token, `host.updateSuperTokenLogic` will revert
		NON_UPGRADABLE,
		/// Upgradable through `host.updateSuperTokenLogic` operation
		SEMI_UPGRADABLE,
		/// Always using the latest super token logic
		FULL_UPGRADABE
	}

	/**
	 * @dev Create new super token wrapper for the underlying ERC20 token
	 * @param underlyingToken Underlying ERC20 token
	 * @param underlyingDecimals Underlying token decimals
	 * @param upgradability Upgradability mode
	 * @param name Super token name
	 * @param symbol Super token symbol
	 */
	function createERC20Wrapper(
		IERC20 underlyingToken,
		uint8 underlyingDecimals,
		Upgradability upgradability,
		string calldata name,
		string calldata symbol
	) external returns (ISuperToken superToken);

	/**
	 * @dev Create new super token wrapper for the underlying ERC20 token with extra token info
	 * @param underlyingToken Underlying ERC20 token
	 * @param upgradability Upgradability mode
	 * @param name Super token name
	 * @param symbol Super token symbol
	 *
	 * NOTE:
	 * - It assumes token provide the .decimals() function
	 */
	function createERC20Wrapper(
		ERC20WithTokenInfo underlyingToken,
		Upgradability upgradability,
		string calldata name,
		string calldata symbol
	) external returns (ISuperToken superToken);

	function initializeCustomSuperToken(address customSuperTokenProxy) external;

	/**
	 * @dev Super token logic created event
	 * @param tokenLogic Token logic address
	 */
	event SuperTokenLogicCreated(ISuperToken indexed tokenLogic);

	/**
	 * @dev Super token created event
	 * @param token Newly created super token address
	 */
	event SuperTokenCreated(ISuperToken indexed token);

	/**
	 * @dev Custom super token created event
	 * @param token Newly created custom super token address
	 */
	event CustomSuperTokenCreated(ISuperToken indexed token);
}

/**
 * @title Super agreement interface
 * @author Superfluid
 */
interface ISuperAgreement {
	/**
	 * @dev Get the type of the agreement class
	 */
	function agreementType() external view returns (bytes32);

	/**
	 * @dev Calculate the real-time balance for the account of this agreement class
	 * @param account Account the state belongs to
	 * @param time Time used for the calculation
	 * @return dynamicBalance Dynamic balance portion of real-time balance of this agreement
	 * @return deposit Account deposit amount of this agreement
	 * @return owedDeposit Account owed deposit amount of this agreement
	 */
	function realtimeBalanceOf(
		ISuperfluidToken token,
		address account,
		uint256 time
	)
		external
		view
		returns (
			int256 dynamicBalance,
			uint256 deposit,
			uint256 owedDeposit
		);
}

/**
 * @title Constant Flow Agreement interface
 * @author Superfluid
 */
abstract contract IConstantFlowAgreementV1 is ISuperAgreement {
	/// @dev ISuperAgreement.agreementType implementation
	function agreementType() external pure override returns (bytes32) {
		return
			keccak256(
				"org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
			);
	}

	/**
	 * @notice Get the maximum flow rate allowed with the deposit
	 * @dev The deposit is clipped and rounded down
	 * @param deposit Deposit amount used for creating the flow
	 * @return flowRate The maximum flow rate
	 */
	function getMaximumFlowRateFromDeposit(
		ISuperfluidToken token,
		uint256 deposit
	) external view virtual returns (int96 flowRate);

	/**
	 * @notice Get the deposit required for creating the flow
	 * @dev Calculates the deposit based on the liquidationPeriod and flowRate
	 * @param flowRate Flow rate to be tested
	 * @return deposit The deposit amount based on flowRate and liquidationPeriod
	 * - if calculated deposit (flowRate * liquidationPeriod) is less
	 *   than the minimum deposit, we use the minimum deposit otherwise
	 *   we use the calculated deposit
	 */
	function getDepositRequiredForFlowRate(
		ISuperfluidToken token,
		int96 flowRate
	) external view virtual returns (uint256 deposit);

	/**
	 * @dev Returns whether it is the patrician period based on host.getNow()
	 * @param account The account we are interested in
	 * @return isCurrentlyPatricianPeriod Whether it is currently the patrician period dictated by governance
	 * @return timestamp The value of host.getNow()
	 */
	function isPatricianPeriodNow(ISuperfluidToken token, address account)
		public
		view
		virtual
		returns (bool isCurrentlyPatricianPeriod, uint256 timestamp);

	/**
	 * @dev Returns whether it is the patrician period based on timestamp
	 * @param account The account we are interested in
	 * @param timestamp The timestamp we are interested in observing the result of isPatricianPeriod
	 * @return bool Whether it is currently the patrician period dictated by governance
	 */
	function isPatricianPeriod(
		ISuperfluidToken token,
		address account,
		uint256 timestamp
	) public view virtual returns (bool);

	/**
	 * @dev msgSender from `ctx` updates permissions for the `flowOperator` with `flowRateAllowance`
	 * @param token Super token address
	 * @param flowOperator The permission grantee address
	 * @param permissions A bitmask representation of the granted permissions
	 * @param flowRateAllowance The flow rate allowance the `flowOperator` is granted (only goes down)
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 */
	function updateFlowOperatorPermissions(
		ISuperfluidToken token,
		address flowOperator,
		uint8 permissions,
		int96 flowRateAllowance,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

	/**
	 * @dev msgSender from `ctx` grants `flowOperator` all permissions with flowRateAllowance as type(int96).max
	 * @param token Super token address
	 * @param flowOperator The permission grantee address
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 */
	function authorizeFlowOperatorWithFullControl(
		ISuperfluidToken token,
		address flowOperator,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

	/**
	 * @notice msgSender from `ctx` revokes `flowOperator` create/update/delete permissions
	 * @dev `permissions` and `flowRateAllowance` will both be set to 0
	 * @param token Super token address
	 * @param flowOperator The permission grantee address
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 */
	function revokeFlowOperatorWithFullControl(
		ISuperfluidToken token,
		address flowOperator,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

	/**
	 * @notice Get the permissions of a flow operator between `sender` and `flowOperator` for `token`
	 * @param token Super token address
	 * @param sender The permission granter address
	 * @param flowOperator The permission grantee address
	 * @return flowOperatorId The keccak256 hash of encoded string "flowOperator", sender and flowOperator
	 * @return permissions A bitmask representation of the granted permissions
	 * @return flowRateAllowance The flow rate allowance the `flowOperator` is granted (only goes down)
	 */
	function getFlowOperatorData(
		ISuperfluidToken token,
		address sender,
		address flowOperator
	)
		public
		view
		virtual
		returns (
			bytes32 flowOperatorId,
			uint8 permissions,
			int96 flowRateAllowance
		);

	/**
	 * @notice Get flow operator using flowOperatorId
	 * @param token Super token address
	 * @param flowOperatorId The keccak256 hash of encoded string "flowOperator", sender and flowOperator
	 * @return permissions A bitmask representation of the granted permissions
	 * @return flowRateAllowance The flow rate allowance the `flowOperator` is granted (only goes down)
	 */
	function getFlowOperatorDataByID(
		ISuperfluidToken token,
		bytes32 flowOperatorId
	)
		external
		view
		virtual
		returns (uint8 permissions, int96 flowRateAllowance);

	/**
	 * @notice Create a flow betwen ctx.msgSender and receiver
	 * @dev flowId (agreementId) is the keccak256 hash of encoded sender and receiver
	 * @param token Super token address
	 * @param receiver Flow receiver address
	 * @param flowRate New flow rate in amount per second
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 *
	 * - AgreementCreated
	 *   - agreementId - can be used in getFlowByID
	 *   - agreementData - abi.encode(address flowSender, address flowReceiver)
	 *
	 * - A deposit is taken as safety margin for the solvency agents
	 * - A extra gas fee may be taken to pay for solvency agent liquidations
	 */
	function createFlow(
		ISuperfluidToken token,
		address receiver,
		int96 flowRate,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

	/**
	 * @notice Create a flow between sender and receiver
	 * @dev A flow created by an approved flow operator (see above for details on callbacks)
	 * @param token Super token address
	 * @param sender Flow sender address (has granted permissions)
	 * @param receiver Flow receiver address
	 * @param flowRate New flow rate in amount per second
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 */
	function createFlowByOperator(
		ISuperfluidToken token,
		address sender,
		address receiver,
		int96 flowRate,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

	/**
	 * @notice Update the flow rate between ctx.msgSender and receiver
	 * @dev flowId (agreementId) is the keccak256 hash of encoded sender and receiver
	 * @param token Super token address
	 * @param receiver Flow receiver address
	 * @param flowRate New flow rate in amount per second
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 *
	 * - AgreementUpdated
	 *   - agreementId - can be used in getFlowByID
	 *   - agreementData - abi.encode(address flowSender, address flowReceiver)
	 *
	 * - Only the flow sender may update the flow rate
	 * - Even if the flow rate is zero, the flow is not deleted
	 * from the system
	 * - Deposit amount will be adjusted accordingly
	 * - No new gas fee is charged
	 */
	function updateFlow(
		ISuperfluidToken token,
		address receiver,
		int96 flowRate,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

	/**
	 * @notice Update a flow between sender and receiver
	 * @dev A flow updated by an approved flow operator (see above for details on callbacks)
	 * @param token Super token address
	 * @param sender Flow sender address (has granted permissions)
	 * @param receiver Flow receiver address
	 * @param flowRate New flow rate in amount per second
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 */
	function updateFlowByOperator(
		ISuperfluidToken token,
		address sender,
		address receiver,
		int96 flowRate,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

	/**
	 * @dev Get the flow data between `sender` and `receiver` of `token`
	 * @param token Super token address
	 * @param sender Flow receiver
	 * @param receiver Flow sender
	 * @return timestamp Timestamp of when the flow is updated
	 * @return flowRate The flow rate
	 * @return deposit The amount of deposit the flow
	 * @return owedDeposit The amount of owed deposit of the flow
	 */
	function getFlow(
		ISuperfluidToken token,
		address sender,
		address receiver
	)
		external
		view
		virtual
		returns (
			uint256 timestamp,
			int96 flowRate,
			uint256 deposit,
			uint256 owedDeposit
		);

	/**
	 * @notice Get flow data using agreementId
	 * @dev flowId (agreementId) is the keccak256 hash of encoded sender and receiver
	 * @param token Super token address
	 * @param agreementId The agreement ID
	 * @return timestamp Timestamp of when the flow is updated
	 * @return flowRate The flow rate
	 * @return deposit The deposit amount of the flow
	 * @return owedDeposit The owed deposit amount of the flow
	 */
	function getFlowByID(ISuperfluidToken token, bytes32 agreementId)
		external
		view
		virtual
		returns (
			uint256 timestamp,
			int96 flowRate,
			uint256 deposit,
			uint256 owedDeposit
		);

	/**
	 * @dev Get the aggregated flow info of the account
	 * @param token Super token address
	 * @param account Account for the query
	 * @return timestamp Timestamp of when a flow was last updated for account
	 * @return flowRate The net flow rate of token for account
	 * @return deposit The sum of all deposits for account's flows
	 * @return owedDeposit The sum of all owed deposits for account's flows
	 */
	function getAccountFlowInfo(ISuperfluidToken token, address account)
		external
		view
		virtual
		returns (
			uint256 timestamp,
			int96 flowRate,
			uint256 deposit,
			uint256 owedDeposit
		);

	/**
	 * @dev Get the net flow rate of the account
	 * @param token Super token address
	 * @param account Account for the query
	 * @return flowRate Net flow rate
	 */
	function getNetFlow(ISuperfluidToken token, address account)
		external
		view
		virtual
		returns (int96 flowRate);

	/**
	 * @notice Delete the flow between sender and receiver
	 * @dev flowId (agreementId) is the keccak256 hash of encoded sender and receiver
	 * @param token Super token address
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 * @param receiver Flow receiver address
	 *
	 * - AgreementTerminated
	 *   - agreementId - can be used in getFlowByID
	 *   - agreementData - abi.encode(address flowSender, address flowReceiver)
	 *
	 * - Both flow sender and receiver may delete the flow
	 * - If Sender account is insolvent or in critical state, a solvency agent may
	 *   also terminate the agreement
	 * - Gas fee may be returned to the sender
	 */
	function deleteFlow(
		ISuperfluidToken token,
		address sender,
		address receiver,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

	/**
	 * @notice Delete the flow between sender and receiver
	 * @dev A flow deleted by an approved flow operator (see above for details on callbacks)
	 * @param token Super token address
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 * @param receiver Flow receiver address
	 */
	function deleteFlowByOperator(
		ISuperfluidToken token,
		address sender,
		address receiver,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

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
	 * @dev Flow updated extension event
	 * @param flowOperator Flow operator address - the Context.msgSender
	 * @param deposit The deposit amount for the stream
	 */
	event FlowUpdatedExtension(address indexed flowOperator, uint256 deposit);
}

/**
 * @title Instant Distribution Agreement interface
 * @author Superfluid
 *
 * @notice
 *   - A publisher can create as many as indices as possibly identifiable with `indexId`.
 *     - `indexId` is deliberately limited to 32 bits, to avoid the chance for sha-3 collision.
 *       Despite knowing sha-3 collision is only theoretical.
 *   - A publisher can create a subscription to an index for any subscriber.
 *   - A subscription consists of:
 *     - The index it subscribes to.
 *     - Number of units subscribed.
 *   - An index consists of:
 *     - Current value as `uint128 indexValue`.
 *     - Total units of the approved subscriptions as `uint128 totalUnitsApproved`.
 *     - Total units of the non approved subscription as `uint128 totalUnitsPending`.
 *   - A publisher can update an index with a new value that doesn't decrease.
 *   - A publisher can update a subscription with any number of units.
 *   - A publisher or a subscriber can delete a subscription and reset its units to zero.
 *   - A subscriber must approve the index in order to receive distributions from the publisher
 *     each time the index is updated.
 *     - The amount distributed is $$\Delta{index} * units$$
 *   - Distributions to a non approved subscription stays in the publisher's deposit until:
 *     - the subscriber approves the subscription (side effect),
 *     - the publisher updates the subscription (side effect),
 *     - the subscriber deletes the subscription even if it is never approved (side effect),
 *     - or the subscriber can explicitly claim them.
 */
abstract contract IInstantDistributionAgreementV1 is ISuperAgreement {
	/// @dev ISuperAgreement.agreementType implementation
	function agreementType() external pure override returns (bytes32) {
		return
			keccak256(
				"org.superfluid-finance.agreements.InstantDistributionAgreement.v1"
			);
	}

	/**************************************************************************
	 * Index operations
	 *************************************************************************/

	/**
	 * @dev Create a new index for the publisher
	 * @param token Super token address
	 * @param indexId Id of the index
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 *
	 * None
	 */
	function createIndex(
		ISuperfluidToken token,
		uint32 indexId,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

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
	 * @dev Query the data of a index
	 * @param token Super token address
	 * @param publisher The publisher of the index
	 * @param indexId Id of the index
	 * @return exist Does the index exist
	 * @return indexValue Value of the current index
	 * @return totalUnitsApproved Total units approved for the index
	 * @return totalUnitsPending Total units pending approval for the index
	 */
	function getIndex(
		ISuperfluidToken token,
		address publisher,
		uint32 indexId
	)
		external
		view
		virtual
		returns (
			bool exist,
			uint128 indexValue,
			uint128 totalUnitsApproved,
			uint128 totalUnitsPending
		);

	/**
	 * @dev Calculate actual distribution amount
	 * @param token Super token address
	 * @param publisher The publisher of the index
	 * @param indexId Id of the index
	 * @param amount The amount of tokens desired to be distributed
	 * @return actualAmount The amount to be distributed after ensuring no rounding errors
	 * @return newIndexValue The index value given the desired amount of tokens to be distributed
	 */
	function calculateDistribution(
		ISuperfluidToken token,
		address publisher,
		uint32 indexId,
		uint256 amount
	)
		external
		view
		virtual
		returns (uint256 actualAmount, uint128 newIndexValue);

	/**
	 * @dev Update index value of an index
	 * @param token Super token address
	 * @param indexId Id of the index
	 * @param indexValue Value of the index
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 *
	 * None
	 */
	function updateIndex(
		ISuperfluidToken token,
		uint32 indexId,
		uint128 indexValue,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

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
	 * @dev Distribute tokens through the index
	 * @param token Super token address
	 * @param indexId Id of the index
	 * @param amount The amount of tokens desired to be distributed
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 *
	 * - This is a convenient version of updateIndex. It adds to the index
	 *   a delta that equals to `amount / totalUnits`
	 * - The actual amount distributed could be obtained via
	 *   `calculateDistribution`. This is due to precision error with index
	 *   value and units data range
	 */
	function distribute(
		ISuperfluidToken token,
		uint32 indexId,
		uint256 amount,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

	/**************************************************************************
	 * Subscription operations
	 *************************************************************************/

	/**
	 * @dev Approve the subscription of an index
	 * @param token Super token address
	 * @param publisher The publisher of the index
	 * @param indexId Id of the index
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 *
	 * - if subscription exist
	 *   - AgreementCreated callback to the publisher:
	 *      - agreementId is for the subscription
	 * - if subscription does not exist
	 *   - AgreementUpdated callback to the publisher:
	 *      - agreementId is for the subscription
	 */
	function approveSubscription(
		ISuperfluidToken token,
		address publisher,
		uint32 indexId,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

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
	 * @notice Revoke the subscription of an index
	 * @dev "Unapproves" the subscription and moves approved units to pending
	 * @param token Super token address
	 * @param publisher The publisher of the index
	 * @param indexId Id of the index
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 *
	 * - AgreementUpdated callback to the publisher:
	 * - agreementId is for the subscription
	 */
	function revokeSubscription(
		ISuperfluidToken token,
		address publisher,
		uint32 indexId,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

	/**
	 * @dev Index unsubscribed event
	 * @param token Super token address
	 * @param publisher Index publisher
	 * @param indexId The specified indexId
	 * @param subscriber The unsubscribed subscriber
	 * @param userData The user provided data
	 */
	event IndexUnsubscribed(
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
	event SubscriptionRevoked(
		ISuperfluidToken indexed token,
		address indexed subscriber,
		address publisher,
		uint32 indexId,
		bytes userData
	);

	/**
	 * @dev Update the nuber of units of a subscription
	 * @param token Super token address
	 * @param indexId Id of the index
	 * @param subscriber The subscriber of the index
	 * @param units Number of units of the subscription
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 *
	 * - if subscription exist
	 *   - AgreementCreated callback to the subscriber:
	 *      - agreementId is for the subscription
	 * - if subscription does not exist
	 *   - AgreementUpdated callback to the subscriber:
	 *      - agreementId is for the subscription
	 */
	function updateSubscription(
		ISuperfluidToken token,
		uint32 indexId,
		address subscriber,
		uint128 units,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

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
	 * @dev Get data of a subscription
	 * @param token Super token address
	 * @param publisher The publisher of the index
	 * @param indexId Id of the index
	 * @param subscriber The subscriber of the index
	 * @return exist Does the subscription exist?
	 * @return approved Is the subscription approved?
	 * @return units Units of the suscription
	 * @return pendingDistribution Pending amount of tokens to be distributed for unapproved subscription
	 */
	function getSubscription(
		ISuperfluidToken token,
		address publisher,
		uint32 indexId,
		address subscriber
	)
		external
		view
		virtual
		returns (
			bool exist,
			bool approved,
			uint128 units,
			uint256 pendingDistribution
		);

	/**
	 * @notice Get data of a subscription by agreement ID
	 * @dev indexId (agreementId) is the keccak256 hash of encodePacked("publisher", publisher, indexId)
	 * @param token Super token address
	 * @param agreementId The agreement ID
	 * @return publisher The publisher of the index
	 * @return indexId Id of the index
	 * @return approved Is the subscription approved?
	 * @return units Units of the suscription
	 * @return pendingDistribution Pending amount of tokens to be distributed for unapproved subscription
	 */
	function getSubscriptionByID(ISuperfluidToken token, bytes32 agreementId)
		external
		view
		virtual
		returns (
			address publisher,
			uint32 indexId,
			bool approved,
			uint128 units,
			uint256 pendingDistribution
		);

	/**
	 * @dev List subscriptions of an user
	 * @param token Super token address
	 * @param subscriber The subscriber's address
	 * @return publishers Publishers of the subcriptions
	 * @return indexIds Indexes of the subscriptions
	 * @return unitsList Units of the subscriptions
	 */
	function listSubscriptions(ISuperfluidToken token, address subscriber)
		external
		view
		virtual
		returns (
			address[] memory publishers,
			uint32[] memory indexIds,
			uint128[] memory unitsList
		);

	/**
	 * @dev Delete the subscription of an user
	 * @param token Super token address
	 * @param publisher The publisher of the index
	 * @param indexId Id of the index
	 * @param subscriber The subscriber's address
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 *
	 * - if the subscriber called it
	 *   - AgreementTerminated callback to the publsiher:
	 *      - agreementId is for the subscription
	 * - if the publisher called it
	 *   - AgreementTerminated callback to the subscriber:
	 *      - agreementId is for the subscription
	 */
	function deleteSubscription(
		ISuperfluidToken token,
		address publisher,
		uint32 indexId,
		address subscriber,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

	/**
	 * @dev Claim pending distributions
	 * @param token Super token address
	 * @param publisher The publisher of the index
	 * @param indexId Id of the index
	 * @param subscriber The subscriber's address
	 * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
	 *
	 * The subscription should not be approved yet
	 *
	 * - AgreementUpdated callback to the publisher:
	 * - agreementId is for the subscription
	 */
	function claim(
		ISuperfluidToken token,
		address publisher,
		uint32 indexId,
		address subscriber,
		bytes calldata ctx
	) external virtual returns (bytes memory newCtx);

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

/**
 * @title SuperApp interface
 * @author Superfluid
 * @dev Be aware of the app being jailed, when the word permitted is used.
 */
interface ISuperApp {
	/**
	 * @dev Callback before a new agreement is created.
	 * @param superToken The super token used for the agreement.
	 * @param agreementClass The agreement class address.
	 * @param agreementId The agreementId
	 * @param agreementData The agreement data (non-compressed)
	 * @param ctx The context data.
	 * @return cbdata A free format in memory data the app can use to pass
	 *          arbitary information to the after-hook callback.
	 *
	 * - It will be invoked with `staticcall`, no state changes are permitted.
	 * - Only revert with a "reason" is permitted.
	 */
	function beforeAgreementCreated(
		ISuperToken superToken,
		address agreementClass,
		bytes32 agreementId,
		bytes calldata agreementData,
		bytes calldata ctx
	) external view returns (bytes memory cbdata);

	/**
	 * @dev Callback after a new agreement is created.
	 * @param superToken The super token used for the agreement.
	 * @param agreementClass The agreement class address.
	 * @param agreementId The agreementId
	 * @param agreementData The agreement data (non-compressed)
	 * @param cbdata The data returned from the before-hook callback.
	 * @param ctx The context data.
	 * @return newCtx The current context of the transaction.
	 *
	 * - State changes is permitted.
	 * - Only revert with a "reason" is permitted.
	 */
	function afterAgreementCreated(
		ISuperToken superToken,
		address agreementClass,
		bytes32 agreementId,
		bytes calldata agreementData,
		bytes calldata cbdata,
		bytes calldata ctx
	) external returns (bytes memory newCtx);

	/**
	 * @dev Callback before a new agreement is updated.
	 * @param superToken The super token used for the agreement.
	 * @param agreementClass The agreement class address.
	 * @param agreementId The agreementId
	 * @param agreementData The agreement data (non-compressed)
	 * @param ctx The context data.
	 * @return cbdata A free format in memory data the app can use to pass
	 *          arbitary information to the after-hook callback.
	 *
	 * - It will be invoked with `staticcall`, no state changes are permitted.
	 * - Only revert with a "reason" is permitted.
	 */
	function beforeAgreementUpdated(
		ISuperToken superToken,
		address agreementClass,
		bytes32 agreementId,
		bytes calldata agreementData,
		bytes calldata ctx
	) external view returns (bytes memory cbdata);

	/**
	 * @dev Callback after a new agreement is updated.
	 * @param superToken The super token used for the agreement.
	 * @param agreementClass The agreement class address.
	 * @param agreementId The agreementId
	 * @param agreementData The agreement data (non-compressed)
	 * @param cbdata The data returned from the before-hook callback.
	 * @param ctx The context data.
	 * @return newCtx The current context of the transaction.
	 *
	 * - State changes is permitted.
	 * - Only revert with a "reason" is permitted.
	 */
	function afterAgreementUpdated(
		ISuperToken superToken,
		address agreementClass,
		bytes32 agreementId,
		bytes calldata agreementData,
		bytes calldata cbdata,
		bytes calldata ctx
	) external returns (bytes memory newCtx);

	/**
	 * @dev Callback before a new agreement is terminated.
	 * @param superToken The super token used for the agreement.
	 * @param agreementClass The agreement class address.
	 * @param agreementId The agreementId
	 * @param agreementData The agreement data (non-compressed)
	 * @param ctx The context data.
	 * @return cbdata A free format in memory data the app can use to pass arbitary information to the after-hook callback.
	 *
	 * - It will be invoked with `staticcall`, no state changes are permitted.
	 * - Revert is not permitted.
	 */
	function beforeAgreementTerminated(
		ISuperToken superToken,
		address agreementClass,
		bytes32 agreementId,
		bytes calldata agreementData,
		bytes calldata ctx
	) external view returns (bytes memory cbdata);

	/**
	 * @dev Callback after a new agreement is terminated.
	 * @param superToken The super token used for the agreement.
	 * @param agreementClass The agreement class address.
	 * @param agreementId The agreementId
	 * @param agreementData The agreement data (non-compressed)
	 * @param cbdata The data returned from the before-hook callback.
	 * @param ctx The context data.
	 * @return newCtx The current context of the transaction.
	 *
	 * - State changes is permitted.
	 * - Revert is not permitted.
	 */
	function afterAgreementTerminated(
		ISuperToken superToken,
		address agreementClass,
		bytes32 agreementId,
		bytes calldata agreementData,
		bytes calldata cbdata,
		bytes calldata ctx
	) external returns (bytes memory newCtx);
}

/**
 * @title Superfluid governance interface
 * @author Superfluid
 */
interface ISuperfluidGovernance {
	/**
	 * @dev Replace the current governance with a new governance
	 */
	function replaceGovernance(ISuperfluid host, address newGov) external;

	/**
	 * @dev Register a new agreement class
	 */
	function registerAgreementClass(ISuperfluid host, address agreementClass)
		external;

	/**
	 * @dev Update logics of the contracts
	 *
	 * - Because they might have inter-dependencies, it is good to have one single function to update them all
	 */
	function updateContracts(
		ISuperfluid host,
		address hostNewLogic,
		address[] calldata agreementClassNewLogics,
		address superTokenFactoryNewLogic
	) external;

	/**
	 * @dev Update supertoken logic contract to the latest that is managed by the super token factory
	 */
	function batchUpdateSuperTokenLogic(
		ISuperfluid host,
		ISuperToken[] calldata tokens
	) external;

	/**
	 * @dev Set configuration as address value
	 */
	function setConfig(
		ISuperfluid host,
		ISuperfluidToken superToken,
		bytes32 key,
		address value
	) external;

	/**
	 * @dev Set configuration as uint256 value
	 */
	function setConfig(
		ISuperfluid host,
		ISuperfluidToken superToken,
		bytes32 key,
		uint256 value
	) external;

	/**
	 * @dev Clear configuration
	 */
	function clearConfig(
		ISuperfluid host,
		ISuperfluidToken superToken,
		bytes32 key
	) external;

	/**
	 * @dev Get configuration as address value
	 */
	function getConfigAsAddress(
		ISuperfluid host,
		ISuperfluidToken superToken,
		bytes32 key
	) external view returns (address value);

	/**
	 * @dev Get configuration as uint256 value
	 */
	function getConfigAsUint256(
		ISuperfluid host,
		ISuperfluidToken superToken,
		bytes32 key
	) external view returns (uint256 value);
}

/**
 * @title Host interface
 * @author Superfluid
 * @notice This is the central contract of the system where super agreement, super app
 * and super token features are connected.
 *
 * The Superfluid host contract is also the entry point for the protocol users,
 * where batch call and meta transaction are provided for UX improvements.
 *
 */
interface ISuperfluid {
	/**************************************************************************
	 * Time
	 *
	 * > The Oracle: You have the sight now, Neo. You are looking at the world without time.
	 * > Neo: Then why can't I see what happens to her?
	 * > The Oracle: We can never see past the choices we don't understand.
	 * >       - The Oracle and Neo conversing about the future of Trinity and the effects of Neo's choices
	 *************************************************************************/

	function getNow() external view returns (uint256);

	/**************************************************************************
	 * Governance
	 *************************************************************************/

	/**
	 * @dev Get the current governance address of the Superfluid host
	 */
	function getGovernance()
		external
		view
		returns (ISuperfluidGovernance governance);

	/**
	 * @dev Replace the current governance with a new one
	 */
	function replaceGovernance(ISuperfluidGovernance newGov) external;

	/**
	 * @dev Governance replaced event
	 * @param oldGov Address of the old governance contract
	 * @param newGov Address of the new governance contract
	 */
	event GovernanceReplaced(
		ISuperfluidGovernance oldGov,
		ISuperfluidGovernance newGov
	);

	/**************************************************************************
	 * Agreement Whitelisting
	 *************************************************************************/

	/**
	 * @dev Register a new agreement class to the system
	 * @param agreementClassLogic Initial agreement class code
	 *
	 * - onlyGovernance
	 */
	function registerAgreementClass(ISuperAgreement agreementClassLogic)
		external;

	/**
	 * @notice Agreement class registered event
	 * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
	 * @param agreementType The agreement type registered
	 * @param code Address of the new agreement
	 */
	event AgreementClassRegistered(bytes32 agreementType, address code);

	/**
	 * @dev Update code of an agreement class
	 * @param agreementClassLogic New code for the agreement class
	 *
	 *  - onlyGovernance
	 */
	function updateAgreementClass(ISuperAgreement agreementClassLogic) external;

	/**
	 * @notice Agreement class updated event
	 * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
	 * @param agreementType The agreement type updated
	 * @param code Address of the new agreement
	 */
	event AgreementClassUpdated(bytes32 agreementType, address code);

	/**
	 * @notice Check if the agreement type is whitelisted
	 * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
	 */
	function isAgreementTypeListed(bytes32 agreementType)
		external
		view
		returns (bool yes);

	/**
	 * @dev Check if the agreement class is whitelisted
	 */
	function isAgreementClassListed(ISuperAgreement agreementClass)
		external
		view
		returns (bool yes);

	/**
	 * @notice Get agreement class
	 * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
	 */
	function getAgreementClass(bytes32 agreementType)
		external
		view
		returns (ISuperAgreement agreementClass);

	/**
	 * @dev Map list of the agreement classes using a bitmap
	 * @param bitmap Agreement class bitmap
	 */
	function mapAgreementClasses(uint256 bitmap)
		external
		view
		returns (ISuperAgreement[] memory agreementClasses);

	/**
	 * @notice Create a new bitmask by adding a agreement class to it
	 * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
	 * @param bitmap Agreement class bitmap
	 */
	function addToAgreementClassesBitmap(uint256 bitmap, bytes32 agreementType)
		external
		view
		returns (uint256 newBitmap);

	/**
	 * @notice Create a new bitmask by removing a agreement class from it
	 * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
	 * @param bitmap Agreement class bitmap
	 */
	function removeFromAgreementClassesBitmap(
		uint256 bitmap,
		bytes32 agreementType
	) external view returns (uint256 newBitmap);

	/**************************************************************************
	 * Super Token Factory
	 **************************************************************************/

	/**
	 * @dev Get the super token factory
	 * @return factory The factory
	 */
	function getSuperTokenFactory()
		external
		view
		returns (ISuperTokenFactory factory);

	/**
	 * @dev Get the super token factory logic (applicable to upgradable deployment)
	 * @return logic The factory logic
	 */
	function getSuperTokenFactoryLogic() external view returns (address logic);

	/**
	 * @dev Update super token factory
	 * @param newFactory New factory logic
	 */
	function updateSuperTokenFactory(ISuperTokenFactory newFactory) external;

	/**
	 * @dev SuperToken factory updated event
	 * @param newFactory Address of the new factory
	 */
	event SuperTokenFactoryUpdated(ISuperTokenFactory newFactory);

	/**
	 * @notice Update the super token logic to the latest
	 * @dev Refer to ISuperTokenFactory.Upgradability for expected behaviours
	 */
	function updateSuperTokenLogic(ISuperToken token) external;

	/**
	 * @dev SuperToken logic updated event
	 * @param code Address of the new SuperToken logic
	 */
	event SuperTokenLogicUpdated(ISuperToken indexed token, address code);

	/**************************************************************************
	 * App Registry
	 *************************************************************************/

	/**
	 * @dev Message sender (must be a contract) declares itself as a super app.
	 * deprecated you should use `registerAppWithKey` or `registerAppByFactory` instead,
	 * because app registration is currently governance permissioned on mainnets.
	 * @param configWord The super app manifest configuration, flags are defined in
	 * `SuperAppDefinitions`
	 */
	function registerApp(uint256 configWord) external;

	/**
	 * @dev App registered event
	 * @param app Address of jailed app
	 */
	event AppRegistered(ISuperApp indexed app);

	/**
	 * @dev Message sender declares itself as a super app.
	 * @param configWord The super app manifest configuration, flags are defined in `SuperAppDefinitions`
	 * @param registrationKey The registration key issued by the governance, needed to register on a mainnet.
	 * @notice See https://github.com/superfluid-finance/protocol-monorepo/wiki/Super-App-White-listing-Guide
	 * On testnets or in dev environment, a placeholder (e.g. empty string) can be used.
	 * While the message sender must be the super app itself, the transaction sender (tx.origin)
	 * must be the deployer account the registration key was issued for.
	 */
	function registerAppWithKey(
		uint256 configWord,
		string calldata registrationKey
	) external;

	/**
	 * @dev Message sender (must be a contract) declares app as a super app
	 * @param configWord The super app manifest configuration, flags are defined in `SuperAppDefinitions`
	 * @notice On mainnet deployments, only factory contracts pre-authorized by governance can use this.
	 * See https://github.com/superfluid-finance/protocol-monorepo/wiki/Super-App-White-listing-Guide
	 */
	function registerAppByFactory(ISuperApp app, uint256 configWord) external;

	/**
	 * @dev Query if the app is registered
	 * @param app Super app address
	 */
	function isApp(ISuperApp app) external view returns (bool);

	/**
	 * @dev Query app level
	 * @param app Super app address
	 */
	function getAppLevel(ISuperApp app) external view returns (uint8 appLevel);

	/**
	 * @dev Get the manifest of the super app
	 * @param app Super app address
	 */
	function getAppManifest(ISuperApp app)
		external
		view
		returns (
			bool isSuperApp,
			bool isJailed,
			uint256 noopMask
		);

	/**
	 * @dev Query if the app has been jailed
	 * @param app Super app address
	 */
	function isAppJailed(ISuperApp app) external view returns (bool isJail);

	/**
	 * @dev Whitelist the target app for app composition for the source app (msg.sender)
	 * @param targetApp The target super app address
	 */
	function allowCompositeApp(ISuperApp targetApp) external;

	/**
	 * @dev Query if source app is allowed to call the target app as downstream app
	 * @param app Super app address
	 * @param targetApp The target super app address
	 */
	function isCompositeAppAllowed(ISuperApp app, ISuperApp targetApp)
		external
		view
		returns (bool isAppAllowed);

	/**************************************************************************
	 * Agreement Framework
	 *
	 * Agreements use these function to trigger super app callbacks, updates
	 * app allowance and charge gas fees.
	 *
	 * These functions can only be called by registered agreements.
	 *************************************************************************/

	/**
	 * @dev (For agreements) StaticCall the app before callback
	 * @param  app               The super app.
	 * @param  callData          The call data sending to the super app.
	 * @param  isTermination     Is it a termination callback?
	 * @param  ctx               Current ctx, it will be validated.
	 * @return cbdata            Data returned from the callback.
	 */
	function callAppBeforeCallback(
		ISuperApp app,
		bytes calldata callData,
		bool isTermination,
		bytes calldata ctx
	)
		external
		returns (
			// onlyAgreement
			// assertValidCtx(ctx)
			bytes memory cbdata
		);

	/**
	 * @dev (For agreements) Call the app after callback
	 * @param  app               The super app.
	 * @param  callData          The call data sending to the super app.
	 * @param  isTermination     Is it a termination callback?
	 * @param  ctx               Current ctx, it will be validated.
	 * @return newCtx            The current context of the transaction.
	 */
	function callAppAfterCallback(
		ISuperApp app,
		bytes calldata callData,
		bool isTermination,
		bytes calldata ctx
	)
		external
		returns (
			// onlyAgreement
			// assertValidCtx(ctx)
			bytes memory newCtx
		);

	/**
	 * @dev (For agreements) Create a new callback stack
	 * @param  ctx                     The current ctx, it will be validated.
	 * @param  app                     The super app.
	 * @param  appAllowanceGranted     App allowance granted so far.
	 * @param  appAllowanceUsed        App allowance used so far.
	 * @return newCtx                  The current context of the transaction.
	 */
	function appCallbackPush(
		bytes calldata ctx,
		ISuperApp app,
		uint256 appAllowanceGranted,
		int256 appAllowanceUsed,
		ISuperfluidToken appAllowanceToken
	)
		external
		returns (
			// onlyAgreement
			// assertValidCtx(ctx)
			bytes memory newCtx
		);

	/**
	 * @dev (For agreements) Pop from the current app callback stack
	 * @param  ctx                     The ctx that was pushed before the callback stack.
	 * @param  appAllowanceUsedDelta   App allowance used by the app.
	 * @return newCtx                  The current context of the transaction.
	 *
	 * - Here we cannot do assertValidCtx(ctx), since we do not really save the stack in memory.
	 * - Hence there is still implicit trust that the agreement handles the callback push/pop pair correctly.
	 */
	function appCallbackPop(bytes calldata ctx, int256 appAllowanceUsedDelta)
		external
		returns (
			// onlyAgreement
			bytes memory newCtx
		);

	/**
	 * @dev (For agreements) Use app allowance.
	 * @param  ctx                      The current ctx, it will be validated.
	 * @param  appAllowanceWantedMore   See app allowance for more details.
	 * @param  appAllowanceUsedDelta    See app allowance for more details.
	 * @return newCtx                   The current context of the transaction.
	 */
	function ctxUseAllowance(
		bytes calldata ctx,
		uint256 appAllowanceWantedMore,
		int256 appAllowanceUsedDelta
	)
		external
		returns (
			// onlyAgreement
			// assertValidCtx(ctx)
			bytes memory newCtx
		);

	/**
	 * @dev (For agreements) Jail the app.
	 * @param  app                     The super app.
	 * @param  reason                  Jail reason code.
	 * @return newCtx                  The current context of the transaction.
	 */
	function jailApp(
		bytes calldata ctx,
		ISuperApp app,
		uint256 reason
	)
		external
		returns (
			// onlyAgreement
			// assertValidCtx(ctx)
			bytes memory newCtx
		);

	/**
	 * @dev Jail event for the app
	 * @param app Address of jailed app
	 * @param reason Reason the app is jailed (see Definitions.sol for the full list)
	 */
	event Jail(ISuperApp indexed app, uint256 reason);

	/**************************************************************************
	 * Contextless Call Proxies
	 *
	 * NOTE: For EOAs or non-app contracts, they are the entry points for interacting
	 * with agreements or apps.
	 *
	 * NOTE: The contextual call data should be generated using
	 * abi.encodeWithSelector. The context parameter should be set to "0x",
	 * an empty bytes array as a placeholder to be replaced by the host
	 * contract.
	 *************************************************************************/

	/**
	 * @dev Call agreement function
	 * @param agreementClass The agreement address you are calling
	 * @param callData The contextual call data with placeholder ctx
	 * @param userData Extra user data being sent to the super app callbacks
	 */
	function callAgreement(
		ISuperAgreement agreementClass,
		bytes calldata callData,
		bytes calldata userData
	)
		external
		returns (
			//cleanCtx
			//isAgreement(agreementClass)
			bytes memory returnedData
		);

	/**
	 * @notice Call app action
	 * @dev Main use case is calling app action in a batch call via the host
	 * @param callData The contextual call data
	 *
	 * See "Contextless Call Proxies" above for more about contextual call data.
	 */
	function callAppAction(ISuperApp app, bytes calldata callData)
		external
		returns (
			//cleanCtx
			//isAppActive(app)
			//isValidAppAction(callData)
			bytes memory returnedData
		);

	/**************************************************************************
	 * Contextual Call Proxies and Context Utilities
	 *
	 * For apps, they must use context they receive to interact with
	 * agreements or apps.
	 *
	 * The context changes must be saved and returned by the apps in their
	 * callbacks always, any modification to the context will be detected and
	 * the violating app will be jailed.
	 *************************************************************************/

	/**
	 * @dev Context Struct
	 *
	 * on backward compatibility:
	 * - Non-dynamic fields are padded to 32bytes and packed
	 * - Dynamic fields are referenced through a 32bytes offset to their "parents" field (or root)
	 * - The order of the fields hence should not be rearranged in order to be backward compatible:
	 *    - non-dynamic fields will be parsed at the same memory location,
	 *    - and dynamic fields will simply have a greater offset than it was.
	 */
	struct Context {
		//
		// Call context
		//
		// callback level
		uint8 appLevel;
		// type of call
		uint8 callType;
		// the system timestamp
		uint256 timestamp;
		// The intended message sender for the call
		address msgSender;
		//
		// Callback context
		//
		// For callbacks it is used to know which agreement function selector is called
		bytes4 agreementSelector;
		// User provided data for app callbacks
		bytes userData;
		//
		// App context
		//
		// app allowance granted
		uint256 appAllowanceGranted;
		// app allowance wanted by the app callback
		uint256 appAllowanceWanted;
		// app allowance used, allowing negative values over a callback session
		int256 appAllowanceUsed;
		// app address
		address appAddress;
		// app allowance in super token
		ISuperfluidToken appAllowanceToken;
	}

	function callAgreementWithContext(
		ISuperAgreement agreementClass,
		bytes calldata callData,
		bytes calldata userData,
		bytes calldata ctx
	)
		external
		returns (
			// requireValidCtx(ctx)
			// onlyAgreement(agreementClass)
			bytes memory newCtx,
			bytes memory returnedData
		);

	function callAppActionWithContext(
		ISuperApp app,
		bytes calldata callData,
		bytes calldata ctx
	)
		external
		returns (
			// requireValidCtx(ctx)
			// isAppActive(app)
			bytes memory newCtx
		);

	function decodeCtx(bytes calldata ctx)
		external
		pure
		returns (Context memory context);

	function isCtxValid(bytes calldata ctx) external view returns (bool);

	/**************************************************************************
	 * Batch call
	 **************************************************************************/
	/**
	 * @dev Batch operation data
	 */
	struct Operation {
		// Operation type. Defined in BatchOperation (Definitions.sol)
		uint32 operationType;
		// Operation target
		address target;
		// Data specific to the operation
		bytes data;
	}

	/**
	 * @dev Batch call function
	 * @param operations Array of batch operations
	 */
	function batchCall(Operation[] memory operations) external;

	/**
	 * @dev Batch call function for trusted forwarders (EIP-2771)
	 * @param operations Array of batch operations
	 */
	function forwardBatchCall(Operation[] memory operations) external;

	/**************************************************************************
	 * Function modifiers for access control and parameter validations
	 *
	 * While they cannot be explicitly stated in function definitions, they are
	 * listed in function definition comments instead for clarity.
	 *
	 * TODO: turning these off because solidity-coverage doesn't like it
	 *************************************************************************/

	/* /// @dev The current superfluid context is clean.
     modifier cleanCtx() virtual;

     /// @dev Require the ctx being valid.
     modifier requireValidCtx(bytes memory ctx) virtual;

     /// @dev Assert the ctx being valid.
     modifier assertValidCtx(bytes memory ctx) virtual;

     /// @dev The agreement is a listed agreement.
     modifier isAgreement(ISuperAgreement agreementClass) virtual;

     // onlyGovernance

     /// @dev The msg.sender must be a listed agreement.
     modifier onlyAgreement() virtual;

     /// @dev The app is registered and not jailed.
     modifier isAppActive(ISuperApp app) virtual; */
}
