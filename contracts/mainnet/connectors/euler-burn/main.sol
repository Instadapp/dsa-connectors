//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IEToken {
    function burnDTokens(uint subAccountId) external;
    function burnETokens(uint subAccountId) external;
}

contract ConnectV2EulerBurn {

    event LogBurn(address token, uint256 subAccountId);

    function burnDTokens(address dtoken, uint256 subAccountId, uint256 getId, uint256 setId)
        external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
    {

        IEToken(dtoken).burnDTokens(subAccountId);

        _eventName = "LogBurn(address,uint256)";
		_eventParam = abi.encode(dtoken, subAccountId);
    }

     function burnETokens(address etoken, uint256 subAccountId, uint256 getId, uint256 setId)
        external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
    {

        IEToken(etoken).burnDTokens(subAccountId);

        _eventName = "LogBurn(address,uint256)";
		_eventParam = abi.encode(etoken, subAccountId);
    }


	string public constant name = "Euler-Burn-v1.0";
}