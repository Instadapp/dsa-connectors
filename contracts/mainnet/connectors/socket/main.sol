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

abstract contract SocketConnectorBridge is Basic {

    address constant registry = 0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0;

    /**
     * @dev socket API bridge handler
     * @param _txData - contains data returned from socket build-tx API. Struct defined in interfaces.sol
     * @param _ethAmt - Eth to bridge for .value()
     */
    function socketBridge(
        bytes memory _txData,
        uint _ethAmt
    ) internal returns (bool _success) {
        (_success, ) = registry.call{value: _ethAmt}(_txData);
        require(_success, "Socket-swap-failed");
    }
}

abstract contract SocketConnectorResolver is SocketConnectorBridge {

    /**
     * @dev Gets Allowance target from registry.
     * @param _route route number
     */
    function getAllowanceTarget(uint _route) internal view returns (address _allowanceTarget) {
        ISocketRegistry.RouteData memory data =  ISocketRegistry(registry).routes(_route);
        return data.route;
    }
}

abstract contract SocketConnector is SocketConnectorResolver {

    /**
     * @dev Bridge Token.
     * @notice Bridge Token on Socket.
     * @param _token token address on source chain
     * @param _txData tx data for calling
     * @param _route route number
     * @param _amount amount to bridge
     * @param _sourceChain Source chain id
     * @param _targetChain Source chain id
     * @param _recipient address of recipient
    */
    function bridge (
        address _token,
        bytes memory _txData,
        uint256 _route,
        uint256 _amount,
        uint256 _targetChain,
        address _recipient
    )
        external payable returns (string memory _eventName, bytes memory _eventParam) 
    {
        uint _ethAmt;

        if(_token == ethAddr) {
            _ethAmt = _amount;
        } else {
            TokenInterface _tokenContract = TokenInterface(_token);
            _tokenContract.approve(getAllowanceTarget(_route), _amount);
        }

        socketBridge(_txData, _ethAmt);

        _eventName = "LogSocketBridge(address,uint256,uint256,uint256,address)";
		_eventParam = abi.encode(
			_token,
			_amount,
			block.chainid,
			_targetChain,
			_recipient
		);
    }
}

contract ConnectV2Socket is SocketConnector {
	string public constant name = "Socket-v1.0";
}
