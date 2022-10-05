//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import './helpers.sol';
import './events.sol';
import './hardhat/console.sol';

abstract contract Morpho is Helpers, Events {
    
	function deposit (
        Underlying _pool,
        address _tokenAddress,
        address _poolTokenAddress, // if address weth (send eth)
        uint256 _amount, // if max, check balance
        uint256 _maxGasForMatching,
        uint256 _getId,
		uint256 _setId
    ) external payable returns(string memory _eventName, bytes memory _eventParam) {

        require(_pool == Underlying.AAVEV2 || _pool == Underlying.COMPOUNDV2, 'protocol not supported');

        uint256 _amt = getUint(_getId, _amount);

        bool _isETH ? _tokenAddress == ethAddr;
        address _token = _isETH ? wethAddr : _tokenAddress

        TokenInterface _tokenContract = TokenInterface(_token);

        if(_amt == uint256(-1)) {
            _amt = _isETH ? address(this).balance : _tokenContract.balanceOf(address(this));
        }

        if(_isETH) convertEthToWeth(_isETH, _tokenContract, _amt);

        _pool == Underlying.AAVEV2 
        ?
            approve(_tokenContract, morphoAave, _amt);
            morphoAave.supply(_poolTokenAddress, address(this), _amt, _maxGasForMatching);
        :
            approve(_tokenContract, morphoCompound, _amt);
            morphoCompound.supply(_poolTokenAddress, address(this), _amt, _maxGasForMatching);

        setUint(_setId, _amt);

        _eventName = "LogDeposit(uint256,address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_pool,
            _tokenAddress,
			_poolTokenAddress,
			_amt,
			_maxGasForMatching,
			_getId,
			_setId
		);	
	}

    function borrow (
        Underlying _pool,
        address _tokenAddress,
        address _poolTokenAddress, //todo: dTokenaAddress? // if address weth (send eth)
        uint256 _amount,
        uint256 _maxGasForMatching
        uint256 _getId,
        uint256 _setId
    ) external payable returns(string memory _eventName, bytes memory _eventParam) {

        require(_pool == Underlying.AAVEV2 || _pool == Underlying.COMPOUNDV2, 'protocol not supported');

        uint256 _amt = getUint(_getId, _amount);

        bool _isETH ? _tokenAddress == ethAddr;
        address _token = _isETH ? wethAddr : _tokenAddress;

        if(_pool == Underlying.AAVEV2) {
            morphoAave.borrow(_poolTokenAddress, _amt, _maxGasForMatching);
        } else {
            morphoCompound.borrow(_poolTokenAddress, _amt, _maxGasForMatching);
        }

        if(_isETH) convertWethToEth(_isETH, tokenInterface(_token), _amt);

        setUint(_setId, _amt);

        _eventName = "LogBorrow(uint256,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_pool,
			_poolTokenAddress,
			_amt,
			_maxGasForMatching,
			_getId,
			_setId
		);
    }

    function withdraw (
        Underlying _pool,
        address _tokenAddress,
        address _poolTokenAddress, // if address weth (send eth)
        uint256 _amount, // amount max
        uint256 _getId,
        uint256 _setId
    ) external payable returns(string memory _eventName, bytes memory _eventParam) {

        require(_pool == Underlying.AAVEV2 || _pool == Underlying.COMPOUNDV2, 'protocol not supported');

        uint256 _amt = getUint(_getId, _amount);
        bool _isETH ? _tokenAddress == ethAddr;
        address _token = _isETH ? wethAddr : _tokenAddress;

        if (_amt == uint256(-1)) _amt = _poolTokenAddress.balanceOf(address(this));

        if(_pool == Underlying.AAVEV2) {
            morphoAave.withdraw(_poolTokenAddress, _amt);
        } else {
            morphoCompound.withdraw(_poolTokenAddress, _amt);
        }

        convertWethToEth(_isETH, TokenInterface(_token), _amt);

        setUint(_setId, _amt);

		_eventName = "LogWithdraw(uint256,bool,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(_pool, _isETH, _poolTokenAddress, _amt, _getId, _setId);

    }

    function payback (
        Underlying _pool,
        address _tokenAddress,
        address _poolTokenAddress, // if address weth (send eth)
        uint256 _amount, // max value
        uint256 _getId,
        uint256 _setId
    ) external payable returns(string memory _eventName, bytes memory _eventParam) {

        require(_pool == Underlying.AAVEV2 || _pool == Underlying.COMPOUNDV2, 'protocol not supported');

        bool _isETH ? _tokenAddress == ethAddr;
        uint256 _amt = getUint(_getId, _amount);
        address _token = _isETH ? wethAddr : _tokenAddress;

        if(_amt == uint256(-1)) {
            _amt = _isETH ? _amt = address(this).balance : TokenInterface(_token).balanceOf(address(this))
        }

        if (_isETH) convertEthToWeth(_isETH, TokenInterface(_token), _amt);

        _pool == Underlying.AAVEV2  
        ? morphoAave.repay(_poolTokenAddress, address(this), _amt)
        : morphoCompound.repay(_poolTokenAddress, address(this), _amt);

        setUint(_setId, _amt);

		_eventName = "LogPayback(uint256,bool,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(_pool, _isETH, _poolTokenAddress, _amt, _getId, _setId);
    }

    function claim (
        Underlying _pool,
        address[] _tokenAddresses, //todo: eth will be claimed as weth currently?
        bool _tradeForMorphoToken
    ) external payable returns(string memory _eventName, bytes memory _eventParam) {

        require(_pool == Underlying.AAVEV2 || _pool == Underlying.COMPOUNDV2, 'protocol not supported');

        _pool == Underlying.AAVEV2
        ? morphoAave.claim(_tokenAddresses, _tradeForMorphoToken)
        : morphoCompound.claim(_tokenAddresses, _tradeForMorphoToken);

        _eventName = "LogClaimed(uint256,address[],bool)";
        _eventParam = abi.encode(_pool, _tokenAddresses, _tradeForMorphoToken);
    }

}

contract ConnectV2Morpho is Morpho {
	string public constant name = "Morpho-v1.0";
}
