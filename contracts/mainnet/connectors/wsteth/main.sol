//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import { Basic } from "../../common/basic.sol";
import './helpers.sol';

/**
 * @title WSTETH.
 * @dev Wrap and Unwrap STETH.
*/

abstract contract WSTETHContract is Helpers, Basic {

    /**
     * @dev Deposit STETH into WSTETH.
     * @notice Wrap STETH into WSTETH
     * @param stethAmt The amount of STETH to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve STETH amount.
     * @param setId ID stores the amount of WSTETH deposited.
     */
    function deposit(
        uint256 stethAmt,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {

        uint256 _amt = getUint(getId, stethAmt);
        _amt = _amt == uint(-1) ? _amt = stethContract.balanceOf(address(this)) : _amt;

        approve(stethContract, address(wstethContract), _amt);

        uint256 _wstethAmt = wstethContract.wrap(_amt);
        setUint(setId, _wstethAmt);

        _eventName = "LogDeposit(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, _wstethAmt, getId, setId);
    }

    /**
     * @dev Withdraw STETH from WSTETH from Smart  Account
     * @notice Unwrap STETH from WSTETH
     * @param wstethAmt The amount of WSTETH to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve WSTETH amount.
     * @param setId ID stores the amount of STETH.
     */
    function withdraw(
        uint256 wstethAmt,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {

        uint256 _amt = getUint(getId, wstethAmt);
        _amt = _amt == uint(-1) ? wstethContract.balanceOf(address(this)) : _amt;

        uint256 _stethAmt = wstethContract.unwrap(_amt);
        setUint(setId, _stethAmt);

        _eventName = "LogWithdraw(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, _stethAmt, getId, setId);
    }
}

contract ConnectV2WSTETH is WSTETHContract {
    string constant public name = "WSTETH-v1.0";
}
