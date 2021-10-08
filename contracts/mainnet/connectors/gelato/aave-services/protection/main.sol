// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

/**
 * @title Aave Protection.
 * @dev Protect DSA against Liquidation risk on Aave with Gelato.
 */

import {Events} from "./events.sol";
import {Helpers} from "./helpers.sol";

abstract contract GAaveProtectionResolver is Events, Helpers {
    /// @dev Function for submitting a protection task
    /// @param _wantedHealthFactor targeted health after protection.
    /// @param _minimumHealthFactor trigger protection when current health
    /// factor is below _minimumHealthFactor.
    /// @param _isPermanent boolean to set a protection as permanent
    function submitProtection(
        uint256 _wantedHealthFactor,
        uint256 _minimumHealthFactor,
        bool _isPermanent
    ) external payable {
        _submitProtection(
            _wantedHealthFactor,
            _minimumHealthFactor,
            _isPermanent
        );
        emit LogSubmitProtection(
            address(this),
            _protectionAction,
            _wantedHealthFactor,
            _minimumHealthFactor,
            _isPermanent
        );
    }

    /// @dev Function for modifying a protection task
    /// @param _wantedHealthFactor targeted health after protection.
    /// @param _minimumHealthFactor trigger protection when current health
    /// factor is below _minimumHealthFactor.
    /// @param _isPermanent boolean to set a protection as permanent
    function updateProtection(
        uint256 _wantedHealthFactor,
        uint256 _minimumHealthFactor,
        bool _isPermanent
    ) external payable {
        _updateProtection(
            _wantedHealthFactor,
            _minimumHealthFactor,
            _isPermanent
        );
        emit LogUpdateProtection(
            address(this),
            _protectionAction,
            _wantedHealthFactor,
            _minimumHealthFactor,
            _isPermanent
        );
    }

    /// @dev Function for cancelling a protection task
    function cancelProtection() external payable {
        _cancelProtection();
        emit LogCancelProtection(address(this), _protectionAction);
    }

    /// @dev Function for cancelling and removing allowance
    /// of aToken to _protectionAction
    function cancelAndRevoke() external payable {
        if (_dsaHasProtection()) _cancelProtection();
        _revokeAllowance();
        emit LogCancelAndRevoke(address(this), _protectionAction);
    }
}

contract GAaveProtectionMainnetConnector is GAaveProtectionResolver {
    // solhint-disable-next-line const-name-snakecase
    string public constant name = "GAaveProtectionMainnetConnector-v1";
}