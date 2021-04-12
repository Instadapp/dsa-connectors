pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// Gelato Data Types
struct Provider {
    address addr;  //  if msg.sender == provider => self-Provider
    address module;  //  e.g. DSA Provider Module
}

struct Condition {
    address inst;  // can be AddressZero for self-conditional Actions
    bytes data;  // can be bytes32(0) for self-conditional Actions
}

enum Operation { Call, Delegatecall }

enum DataFlow { None, In, Out, InAndOut }

struct Action {
    address addr;
    bytes data;
    Operation operation;
    DataFlow dataFlow;
    uint256 value;
    bool termsOkCheck;
}

struct Task {
    Condition[] conditions;  // optional
    Action[] actions;
    uint256 selfProviderGasLimit;  // optional: 0 defaults to gelatoMaxGas
    uint256 selfProviderGasPriceCeil;  // optional: 0 defaults to NO_CEIL
}

struct TaskReceipt {
    uint256 id;
    address userProxy;
    Provider provider;
    uint256 index;
    Task[] tasks;
    uint256 expiryDate;
    uint256 cycleId;  // auto-filled by GelatoCore. 0 for non-cyclic/chained tasks
    uint256 submissionsLeft;
}

struct TaskSpec {
    address[] conditions;   // Address: optional AddressZero for self-conditional actions
    Action[] actions;
    uint256 gasPriceCeil;
}

// Gelato Interface
interface IGelatoInterface {

    /**
     * @dev API to submit a single Task.
    */
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    )
        external;


    /**
     * @dev A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
     * the next one, after they have been executed, where the total number of tasks can
     * be only be an even number
    */
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external;


    /**
     * @dev A Gelato Task Chain consists of 1 or more Tasks that automatically submit
     * the next one, after they have been executed, where the total number of tasks can
     * be an odd number
    */
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external;

    /**
     * @dev Cancel multiple tasks at once
    */
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts) external;

    /**
     * @dev Whitelist new executor, TaskSpec(s) and Module(s) in one tx
    */
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules
    )
        external
        payable;


    /**
     * @dev De-Whitelist TaskSpec(s), Module(s) and withdraw funds from gelato in one tx
    */
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules
    )
        external;
}
