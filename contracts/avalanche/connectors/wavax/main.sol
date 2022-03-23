//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title WAVAX.
 * @dev Wrap and Unwrap WAVAX.
 */

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";
import { Helpers } from "./helpers.sol";

abstract contract Resolver is Events, DSMath, Basic, Helpers {

    /**
     * @dev Deposit AVAX into WAVAX.
     * @notice Wrap AVAX into WAVAX
     * @param amt The amount of AVAX to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of AVAX deposited.
     */
    function deposit(
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        _amt = _amt == uint(-1) ? address(this).balance : _amt;
        wavaxContract.deposit{value: _amt}();
        
        setUint(setId, _amt);

        _eventName = "LogDeposit(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }

    /**
     * @dev Withdraw AVAX from WAVAX from Smart  Account
     * @notice Unwrap AVAX from WAVAX
     * @param amt The amount of wavax to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of AVAX withdrawn.
     */
    function withdraw(
        uint amt,
        uint getId,
        uint setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        _amt = _amt == uint(-1) ? wavaxContract.balanceOf(address(this)) : _amt;
        approve(wavaxContract, wavaxAddr, _amt);
        wavaxContract.withdraw(_amt);

        setUint(setId, _amt);

        _eventName = "LogWithdraw(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }
}

contract ConnectV2WAVAXAvalanche is Resolver {
    string constant public name = "WAVAX-v1.0";
}
