//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title Socket.
 * @dev Multi-chain Bridge Aggregator.
 */

import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import "./events.sol";
import "./interface.sol";

abstract contract SocketConnectorResolver {

    /**
     * @dev Gets Allowance target from registry.
     * @param _route route number
     */
    function getAllowanceTarget(uint _route) internal view returns (address _allowanceTarget) {
        ISocketRegistry registryContr = ISocketRegistry(0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0);
        ISocketRegistry.RouteData memory data = registryContr.routes(_route);
        return data.route;
    }
}

abstract contract SocketConnector is SocketConnectorResolver, Basic {

    address constant registry = 0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0;

    struct BridgeParams {
        bytes txData;
        address token;
        uint256 amount;
	}

    /**
     * @dev Bridge Token.
     * @notice Bridge Token on Socket.
     * @param _token token address on source chain
     * @param _txData tx data for calling
     * @param _route route number
     * @param _amount amount to bridge
     * @param _getId ID to retrieve amount from last spell.
    */
    function bridge (
        address _token,
        bytes memory _txData,
        uint256 _route,
        uint256 _amount,
        uint256 _getId
    )
        external payable returns (string memory _eventName, bytes memory _eventParam) 
    {
        _amount = getUint(_getId, _amount);

        if(_token == ethAddr) {
            _amount = _amount == uint256(-1)
				? address(this).balance
				: _amount;

            (bool success, ) = registry.call{value: _amount}(_txData);
            require(success, "Socket-swap-failed");

        } else {
            TokenInterface _tokenContract = TokenInterface(_token);
            _amount = _amount == uint256(-1)
				? _tokenContract.balanceOf(address(this))
				: _amount;

            _tokenContract.approve(getAllowanceTarget(_route), _amount);
            (bool success, ) = registry.call(_txData);
            require(success, "Socket-swap-failed");
        }

        _eventName = "LogSocketBridge(bytes,address,uint256,uint256)";
		_eventParam = abi.encode(
			_txData,
			_token,
			_amount,
			_getId
		);
    }
}

contract ConnectV2Socket is SocketConnector {
	string public constant name = "Socket-v1.0";
}
