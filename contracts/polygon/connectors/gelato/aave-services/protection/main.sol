// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

/**
 * @title Aave Protection.
 * @dev Protect DSA against Liquidation risk on Aave with Gelato.
 */


import {IERC20} from "./interface.sol";
import {Helpers} from "./helpers.sol";

abstract contract GAaveProtectionResolver is Helpers {
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
    }

    /// @dev Function for cancelling a protection task
    function cancelProtection() external payable {
        _cancelProtection();
    }

    /// @dev Function for cancelling and removing allowance
    /// of aToken to _protectionAction
    function cancelAndRevoke() external payable {
        if (_dsaHasProtection()) _cancelProtection();
        _revokeAllowance();
    }

    function _submitProtection(
        uint256 _wantedHealthFactor,
        uint256 _minimumHealthFactor,
        bool _isPermanent
    ) internal {
        _giveAllowance();

        _aaveServices.submitTask(
            _protectionAction,
            abi.encode(
                _wantedHealthFactor,
                _minimumHealthFactor,
                address(this)
            ),
            _isPermanent
        );
    }

    function _updateProtection(
        uint256 _wantedHealthFactor,
        uint256 _minimumHealthFactor,
        bool _isPermanent
    ) internal {
        _giveAllowance();

        _aaveServices.updateTask(
            _protectionAction,
            abi.encode(
                _wantedHealthFactor,
                _minimumHealthFactor,
                address(this)
            ),
            _isPermanent
        );
    }

    function _cancelProtection() internal {
        _aaveServices.cancelTask(_protectionAction);
    }

    function _giveAllowance() internal {
        address[] memory aTokenList = _getATokenList();
        for (uint256 i = 0; i < aTokenList.length; i++) {
            if (
                !(IERC20(aTokenList[i]).allowance(
                    address(this),
                    _protectionAction
                ) == type(uint256).max)
            ) {
                IERC20(aTokenList[i]).approve(
                    _protectionAction,
                    type(uint256).max
                );
            }
        }
    }

    function _revokeAllowance() internal {
        address[] memory aTokenList = _getATokenList();
        for (uint256 i = 0; i < aTokenList.length; i++) {
            if (
                !(IERC20(aTokenList[i]).allowance(
                    address(this),
                    _protectionAction
                ) == 0)
            ) {
                IERC20(aTokenList[i]).approve(_protectionAction, 0);
            }
        }
    }

    function _getATokenList()
        internal
        view
        returns (address[] memory aTokenList)
    {
        address[] memory underlyingsList = _lendingPool.getReservesList();
        aTokenList = new address[](underlyingsList.length);
        for (uint256 i = 0; i < underlyingsList.length; i++) {
            aTokenList[i] = (_lendingPool.getReserveData(underlyingsList[i]))
                .aTokenAddress;
        }
    }

    function _dsaHasProtection() internal view returns (bool) {
        return
            _aaveServices.taskByUsersAction(address(this), _protectionAction) !=
            bytes32(0);
    }
}

contract GAaveProtectionPolygonConnector is GAaveProtectionResolver {
    // solhint-disable-next-line const-name-snakecase
    string public constant name = "GelatoAaveProtectionPolygonConnector-v1";
}
