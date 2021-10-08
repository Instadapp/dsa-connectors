// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {
    LendingPoolInterface,
    AaveServicesInterface,
    IERC20
} from "./interface.sol";

abstract contract Helpers {
    // solhint-disable-next-line const-name-snakecase
    LendingPoolInterface internal constant _lendingPool =
        LendingPoolInterface(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    // solhint-disable-next-line const-name-snakecase
    AaveServicesInterface internal constant _aaveServices =
        AaveServicesInterface(0xE3d373c78803C1d22cE96bdC43d47542835bBF42);

    // solhint-disable-next-line const-name-snakecase
    address internal constant _protectionAction =
        0xD2579361F3C402938841774ECc1acdd51d3a4345;

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