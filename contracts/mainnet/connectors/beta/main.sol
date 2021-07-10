pragma solidity ^0.7.0;

/**
 * @title Authority.
 * @dev Manage Authorities to DSA.
 */

import { AccountInterface } from "../../common/interfaces.sol";
import { Events } from "./events.sol";

abstract contract Resolver is Events {
    /**
     * @dev Enable beta mode
     * @notice enabling beta mode gives early access to new/risky features
     */
    function enable() external payable returns (string memory _eventName, bytes memory _eventParam) {
        AccountInterface _dsa = AccountInterface(address(this));
        require(!_dsa.isBeta(), "beta-already-enabled");
        _dsa.toggleBeta();

        _eventName = "LogEnableBeta()";
    }

    /**
     * @dev Disable beta mode
     * @notice disabling beta mode removes early access to new/risky features
     */
    function disable() external payable returns (string memory _eventName, bytes memory _eventParam) {
         AccountInterface _dsa = AccountInterface(address(this));
        require(_dsa.isBeta(), "beta-already-disabled");
        _dsa.toggleBeta();

        _eventName = "LogDisableBeta()";
    }
}

contract ConnectV2Beta is Resolver {
    string public constant name = "Beta-v1";
}
