pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Gelato.
 * @dev Automation.
 */

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { IGelatoInterface, Task, Provider, TaskSpec, TaskReceipt } from "./interface.sol";
import { Events } from "./events.sol";

abstract contract GelatoResolver is DSMath, Basic, Events {

    IGelatoInterface internal constant gelato = IGelatoInterface(0x1d681d76ce96E4d70a88A00EBbcfc1E47808d0b8);

    // ===== Gelato ENTRY APIs ======

    /**
     * @dev Enables to use Gelato
     * @notice Enables first time users to  pre-fund eth, whitelist an executor & register the
     * ProviderModuleDSA.sol to be able to use Gelato
     * @param _executor address of single execot node or gelato'S decentralized execution market
     * @param _taskSpecs enables external providers to whitelist TaskSpecs on gelato
     * @param _modules address of ProviderModuleDSA
     * @param _ethToDeposit amount of eth to deposit on Gelato, only for self-providers
     * @param _getId get token amount at this IDs from `InstaMemory` Contract.
     * @param _setId set token amount at this IDs in `InstaMemory` Contract.
    */
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules,
        uint256 _ethToDeposit,
        uint256 _getId,
        uint256 _setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint256 ethToDeposit = getUint(_getId, _ethToDeposit);
        ethToDeposit = ethToDeposit == uint(-1) ? address(this).balance : ethToDeposit;

        gelato.multiProvide{value: ethToDeposit}(
            _executor,
            _taskSpecs,
            _modules
        );

        setUint(_setId, ethToDeposit);

        _eventName = "LogMultiProvide(address,TaskSpec[],address[],uint256,uint256,uint256)";
        _eventParam = abi.encode(_executor, _taskSpecs, _modules, ethToDeposit, _getId, _setId);
    }

    /**
     * @dev Submit task
     * @notice Submits a single, one-time task to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _task Task specifying the condition and the action connectors
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
    */
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        gelato.submitTask(_provider, _task, _expiryDate);

        _eventName = "LogSubmitTask(Provider,Task,uint256)";
        _eventParam = abi.encode(_provider, _task, _expiryDate);
    }

    /**
     * @dev Submit Task Sequences
     * @notice Submits single or mulitple Task Sequences to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _tasks A sequence of Tasks, can be a single or multiples
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
     * @param _cycles How often the Task List should be executed, e.g. 5 times
    */
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        gelato.submitTaskCycle(
            _provider,
            _tasks,
            _expiryDate,
            _cycles
        );

        _eventName = "LogSubmitTaskCycle(Provider,Task[],uint256)";
        _eventParam = abi.encode(_provider, _tasks, _expiryDate);
    }

    /**
     * @dev Submit Task Chains
     * @notice Submits single or mulitple Task Chains to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _tasks A sequence of Tasks, can be a single or multiples
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
     * @param _sumOfRequestedTaskSubmits The TOTAL number of Task auto-submits
     * that should have occured once the cycle is complete
    */
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        gelato.submitTaskChain(
            _provider,
            _tasks,
            _expiryDate,
            _sumOfRequestedTaskSubmits
        );

        _eventName = "LogSubmitTaskChain(Provider,Task[],uint256)";
        _eventParam = abi.encode(_provider, _tasks, _expiryDate);
    }

    // ===== Gelato EXIT APIs ======

    /**
     * @dev Withdraws ETH, de-whitelists Tasks and Modules
     * in one tx
     * @notice Withdraws funds from Gelato, de-whitelists TaskSpecs and Provider Modules
     * in one tx
     * @param _withdrawAmount Amount of ETH to withdraw from Gelato
     * @param _taskSpecs List of Task Specs to de-whitelist, default empty []
     * @param _modules List of Provider Modules to de-whitelist, default empty []
     * @param _getId get token amount at this IDs from `InstaMemory` Contract.
     * @param _setId set token amount at this IDs in `InstaMemory` Contract.
    */
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules,
        uint256 _getId,
        uint256 _setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint256 withdrawAmount = getUint(_getId, _withdrawAmount);
        uint256 balanceBefore = address(this).balance;

        gelato.multiUnprovide(
            withdrawAmount,
            _taskSpecs,
            _modules
        );

        uint256 actualWithdrawAmount = sub(address(this).balance, balanceBefore);

        setUint(_setId, actualWithdrawAmount);

        _eventName = "LogMultiUnprovide(TaskSpec[],address[],uint256,uint256,uint256)";
        _eventParam = abi.encode(_taskSpecs, _modules, actualWithdrawAmount, _getId, _setId);
    }

    /**
     * @dev Cancel Tasks
     * @notice Cancels outstanding Tasks on Gelato
     * @param _taskReceipts List of Task Receipts to cancel
    */
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        gelato.multiCancelTasks(_taskReceipts);

        _eventName = "LogMultiCancelTasks(TaskReceipt[])";
        _eventParam = abi.encode(_taskReceipts);
    }

}

contract ConnectV2Gelato is GelatoResolver {
    string public name = "Gelato-v1";
}
