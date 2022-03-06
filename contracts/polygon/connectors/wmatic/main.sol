//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title WMATIC.
 * @dev Wrap and Unwrap WMATIC.
 */

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";
import { Helpers } from "./helpers.sol";

abstract contract Resolver is Events, DSMath, Basic, Helpers {

    /**
     * @dev Deposit MATIC into WMATIC.
     * @notice Wrap MATIC into WMATIC
     * @param amt The amount of MATIC to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of MATIC deposited.
     */
    function deposit(
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        _amt = _amt == uint(-1) ? address(this).balance : _amt;
        wmaticContract.deposit{value: _amt}();
        
        setUint(setId, _amt);

        _eventName = "LogDeposit(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }

    /**
     * @dev Withdraw MATIC from WMATIC from Smart  Account
     * @notice Unwrap MATIC from WMATIC
     * @param amt The amount of wmatic to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of MATIC withdrawn.
     */
    function withdraw(
        uint amt,
        uint getId,
        uint setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        _amt = _amt == uint(-1) ? wmaticContract.balanceOf(address(this)) : _amt;
        approve(wmaticContract, wmaticAddr, _amt);
        wmaticContract.withdraw(_amt);

        setUint(setId, _amt);

        _eventName = "LogWithdraw(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }
}

contract ConnectV2WMATICPolygon is Resolver {
    string constant public name = "WMATIC-v1.0";
}
