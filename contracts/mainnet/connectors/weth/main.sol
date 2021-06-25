pragma solidity ^0.7.0;

/**
 * @title WETH.
 * @dev Wrap and Unwrap WETH.
 */

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";
import { Helpers } from "./helpers.sol";

abstract contract Resolver is Events, DSMath, Basic, Helpers {

    /**
     * @dev Deposit ETH into WETH.
     * @notice Wrap ETH into WETH
     * @param amt The amount of ETH to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of ETH deposited.
     */
    function deposit(
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        _amt = _amt == uint(-1) ? address(this).balance : _amt;
        wethContract.deposit{value: _amt}();
        
        setUint(setId, _amt);

        _eventName = "LogDeposit(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH from WETH from Smart  Account
     * @notice Unwrap ETH from WETH
     * @param amt The amount of weth to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of ETH withdrawn.
     */
    function withdraw(
        uint amt,
        uint getId,
        uint setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        _amt = _amt == uint(-1) ? wethContract.balanceOf(address(this)) : _amt;
        approve(wethContract, wethAddr, _amt);
        wethContract.withdraw(_amt);

        setUint(setId, _amt);

        _eventName = "LogWithdraw(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }
}

contract ConnectV2WETH is Resolver {
    string constant public name = "WETH-v1.0";
}
