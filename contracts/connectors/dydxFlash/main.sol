pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface, AccountInterface } from "../../common/interfaces.sol";
import { Events } from "./events.sol";
import { DydxFlashInterface } from "./interface.sol";

abstract contract FlashLoanResolver is DSMath, Basic, Events {
    address internal constant dydxAddr = address(0); // check9898 - change to dydx flash contract address

    /**
     * @dev Borrow Flashloan and Cast spells.
     * @param token Token Address.
     * @param tokenAmt Token Amount.
     * @param data targets & data for cast.
     */
    function borrowAndCast(
        address token,
        uint tokenAmt,
        bytes memory data
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        AccountInterface(address(this)).enable(dydxAddr);

        address _token = token == ethAddr ? wethAddr : token;

        DydxFlashInterface(dydxAddr).initiateFlashLoan(_token, tokenAmt, data);

        AccountInterface(address(this)).disable(dydxAddr);

        _eventName = "LogDydxFlashLoan(address,uint256)";
        _eventParam = abi.encode(token, tokenAmt);
    }
}

contract ConnectV2DydxFlashLoan is FlashLoanResolver {
    string public constant name = "dydx-flashloan-v1";
}
