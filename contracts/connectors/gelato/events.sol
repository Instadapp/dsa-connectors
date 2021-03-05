pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { Task, Provider, TaskSpec, TaskReceipt } from "./interface.sol";

contract Events {
    event LogMultiProvide(
        address indexed executor,
        TaskSpec[] indexed taskspecs,
        address[] indexed modules,
        uint256 ethToDeposit,
        uint256 getId,
        uint256 setId
    );

    event LogSubmitTask(
        Provider indexed provider,
        Task indexed task,
        uint256 indexed expiryDate
    );

    event LogSubmitTaskCycle(
        Provider indexed provider,
        Task[] indexed tasks,
        uint256 indexed expiryDate
    );

    event LogSubmitTaskChain(
        Provider indexed provider,
        Task[] indexed tasks,
        uint256 indexed expiryDate
    );

    event LogMultiUnprovide(
        TaskSpec[] indexed taskspecs,
        address[] indexed modules,
        uint256 ethToWithdraw,
        uint256 getId,
        uint256 setId
    );

    event LogMultiCancelTasks(
        TaskReceipt[] indexed taskReceipt
    );
}
