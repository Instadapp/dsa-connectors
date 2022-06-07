//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Socket.
 * @dev Multi-chain Bridge Aggregator.
 */

import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./events.sol";
import "hardhat/console.sol";
abstract contract SocketConnector is Basic {

    struct BridgeParams {
		address payable to; 
        bytes txData;
        address token;
        address allowanceTarget;
        uint256 amount;
	}

    function bridge(BridgeParams memory _params, uint256 _getId)
        external 
        payable 
        returns (string memory _eventName, bytes memory _eventParam) 
    {
        _params.amount = getUint(_getId, _params.amount);

        if(_params.token == ethAddr) {
            _params.amount = _params.amount == uint256(-1)
				? address(this).balance
				: _params.amount;

            (bool success, ) = _params.to.call{value: _params.amount}(_params.txData);
            require(success);

        } else {
            IERC20 _tokenContract = IERC20(_params.token);
            _params.amount = _params.amount == uint256(-1)
				? _tokenContract.balanceOf(address(this))
				: _params.amount;

            console.log("address this balance: ", _tokenContract.balanceOf(address(this)));
            console.log("_params.allowanceTarget: ", _params.allowanceTarget);
            console.log("_params.amount: ", _params.amount);
            _tokenContract.approve(_params.allowanceTarget, _params.amount);
            (bool success, ) = _params.to.call(_params.txData);
            console.log("success: ", success);
            require(success);
        }

        _eventName = "LogSocketBridge(address,bytes,address,address,uint256,uint256)";
		_eventParam = abi.encode(
			_params.to,
			_params.txData,
			_params.token,
			_params.allowanceTarget,
			_params.amount,
			_getId
		);
    }
}

contract ConnectV2Socket is SocketConnector {
	string public constant name = "Socket-v1.0";
}
