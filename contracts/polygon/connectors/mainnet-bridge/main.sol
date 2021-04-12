pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Events } from "./events.sol";

abstract contract MainnetBridgeResolver is Stores, Events {
    /**
     * @dev Withdraw assets to mainnet.
     * @notice Withdraw assets to mainnet by burning the tokens.
     * @param token The address of the token to withdraw. (For MATIC: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of tokens to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdraw(
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        if (token == maticAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            TokenInterface(address(0)).withdraw(_amt);
        } else {
            TokenInterface _token = TokenInterface(token);
            _amt = _amt == uint(-1) ? _token.balanceOf(address(this)) : _amt;
            _token.withdraw(_amt);
            if (token == wmaticAddr) {
                TokenInterface(address(0)).withdraw(_amt);
            }
        }

        setUint(setId, _amt);

        _eventName = "LogWithdraw(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, getId, setId);
    }
}