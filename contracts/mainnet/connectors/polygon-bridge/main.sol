pragma solidity ^0.7.0;

/**
 * @title Polygon Assets Bridge.
 * @dev Polygon assets bridge.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract PolygonBridgeResolver is Events, Helpers {
    /**
     * @dev Deposit assets to the bridge.
     * @notice Deposit assets to the bridge.
     * @param targetDsa The address to receive the token on Polygon
     * @param token The address of the token to deposit. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of tokens to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposit.
    */
    function deposit(
        address targetDsa,
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        if (token == ethAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            migrator.depositEtherFor{value: _amt}(targetDsa);
        } else {
            TokenInterface _token = TokenInterface(token);
            _amt = _amt == uint(-1) ? _token.balanceOf(address(this)) : _amt;
            if (migrator.rootToChildToken(token) != address(0)) {
                approve(_token, erc20Predicate, _amt);
                migrator.depositFor(targetDsa, token, abi.encode(_amt));
            } else {
                approve(_token, address(migratorPlasma), _amt);
                migratorPlasma.depositERC20ForUser(token, targetDsa, _amt);
            }
        }

        setUint(setId, _amt);

        _eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(targetDsa, token, _amt, getId, setId);
    }
}

contract ConnectV2PolygonBridge is PolygonBridgeResolver {
    string public constant name = "Polygon-Bridge-v1.1";
}