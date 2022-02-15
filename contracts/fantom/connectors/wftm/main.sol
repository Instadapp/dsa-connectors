pragma solidity ^0.7.0;

/**
 * @title WFTM.
 * @dev Wrap and Unwrap WFTM.
 */

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";
import { Helpers } from "./helpers.sol";

abstract contract Resolver is Events, DSMath, Basic, Helpers {

    /**
     * @dev Deposit FTM into WFTM.
     * @notice Wrap FTM into WFTM
     * @param amt The amount of FTM to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of FTM deposited.
     */
    function deposit(
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        _amt = _amt == uint(-1) ? address(this).balance : _amt;
        wftmContract.deposit{value: _amt}();
        
        setUint(setId, _amt);

        _eventName = "LogDeposit(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }

    /**
     * @dev Withdraw FTM from WFTM from Smart  Account
     * @notice Unwrap FTM from WFTM
     * @param amt The amount of wFTM to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of FTM withdrawn.
     */
    function withdraw(
        uint amt,
        uint getId,
        uint setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        _amt = _amt == uint(-1) ? wftmContract.balanceOf(address(this)) : _amt;
        approve(wftmContract, wftmAddr, _amt);
        wftmContract.withdraw(_amt);

        setUint(setId, _amt);

        _eventName = "LogWithdraw(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }
}

contract ConnectV2WFTMFantom is Resolver {
    string constant public name = "WFTM-v1.0";
}
