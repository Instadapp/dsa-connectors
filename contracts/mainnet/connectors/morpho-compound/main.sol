//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./helpers.sol";
import "./events.sol";

abstract contract MorphoCompound is Helpers, Events {
	/**
	 * @dev Deposit ETH/ERC20_Token.
	 * @notice Deposit a token to Morpho Compound for lending / collaterization.
	 * @param _tokenAddress The address of underlying token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _poolTokenAddress The address of cToken to deposit.(For ETH: cWETH address)
	 * @param _amount The amount of the token (in underlying) to deposit. (For max: `uint256(-1)`)
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function deposit(
		address _tokenAddress,
		address _poolTokenAddress,
		uint256 _amount,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);

		bool _isETH = _tokenAddress == ethAddr;

		TokenInterface _tokenContract = _isETH
			? TokenInterface(wethAddr)
			: TokenInterface(_tokenAddress);

		if (_amt == uint256(-1)) {
			_amt = _isETH
				? address(this).balance
				: _tokenContract.balanceOf(address(this));
		}

		convertEthToWeth(_isETH, _tokenContract, _amt);

		approve(_tokenContract, address(morphoCompound), _amt);
		morphoCompound.supply(_poolTokenAddress, address(this), _amt);

		setUint(_setId, _amt);

		_eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_poolTokenAddress,
			_amt,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Deposit ETH/ERC20_Token.
	 * @notice Deposit a token to Morpho Compound for lending / collaterization with max gas.
	 * @param _tokenAddress The address of underlying token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _poolTokenAddress The address of cToken to deposit.(For ETH: cWETH address).
	 * @param _amount The amount of the token (in underlying) to deposit. (For max: `uint256(-1)`).
	 * @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function depositWithMaxGas(
		address _tokenAddress,
		address _poolTokenAddress,
		uint256 _amount,
		uint256 _maxGasForMatching,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);

		bool _isETH = _tokenAddress == ethAddr;

		TokenInterface _tokenContract = _isETH
			? TokenInterface(wethAddr)
			: TokenInterface(_tokenAddress);

		if (_amt == uint256(-1)) {
			_amt = _isETH
				? address(this).balance
				: _tokenContract.balanceOf(address(this));
		}

		convertEthToWeth(_isETH, _tokenContract, _amt);

		approve(_tokenContract, address(morphoCompound), _amt);
		morphoCompound.supply(
			_poolTokenAddress,
			address(this),
			_amt,
			_maxGasForMatching
		);

		setUint(_setId, _amt);

		_eventName = "depositWithMaxGas(address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_poolTokenAddress,
			_amt,
			_maxGasForMatching,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Deposit ETH/ERC20_Token.
	 * @notice Deposit a token to Morpho Compound for lending / collaterization on behalf of a user.
	 * @param _tokenAddress The address of underlying token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _poolTokenAddress The address of cToken to deposit.(For ETH: cWETH address)
	 * @param _onBehalf The address of user on behalf to deposit.
	 * @param _amount The amount of the token (in underlying) to deposit. (For max: `uint256(-1)`)
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function depositOnBehalf(
		address _tokenAddress,
		address _poolTokenAddress,
		address _onBehalf,
		uint256 _amount,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);

		bool _isETH = _tokenAddress == ethAddr;

		TokenInterface _tokenContract = _isETH
			? TokenInterface(wethAddr)
			: TokenInterface(_tokenAddress);

		if (_amt == uint256(-1)) {
			_amt = _isETH
				? address(this).balance
				: _tokenContract.balanceOf(address(this));
		}

		if (_isETH) convertEthToWeth(_isETH, _tokenContract, _amt);

		approve(_tokenContract, address(morphoCompound), _amt);
		morphoCompound.supply(_poolTokenAddress, _onBehalf, _amt);

		setUint(_setId, _amt);

		_eventName = "LogDeposit(address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_poolTokenAddress,
			_onBehalf,
			_amt,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Borrow ETH/ERC20_Token.
	 * @notice Borrow a token from Morpho Compound.
	 * @param _tokenAddress The address of underlying token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _poolTokenAddress The address of cToken to borrow.(For ETH: cWETH address)
	 * @param _amount The amount of the token (in underlying) to borrow.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function borrow(
		address _tokenAddress,
		address _poolTokenAddress,
		uint256 _amount,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);

		bool _isETH = _tokenAddress == ethAddr;

		morphoCompound.borrow(_poolTokenAddress, _amt);

		if (_isETH) convertWethToEth(_isETH, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogBorrow(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_poolTokenAddress,
			_amt,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Borrow ETH/ERC20_Token.
	 * @notice Borrow a token from Morpho Compound with max gas.
	 * @param _tokenAddress The address of underlying token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _poolTokenAddress The address of cToken to borrow.(For ETH: cWETH address)
	 * @param _amount The amount of the token (in underlying) to borrow.
	 * @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function borrowWithMaxGas(
		address _tokenAddress,
		address _poolTokenAddress,
		uint256 _amount,
		uint256 _maxGasForMatching,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);

		bool _isETH = _tokenAddress == ethAddr;

		morphoCompound.borrow(_poolTokenAddress, _amt, _maxGasForMatching);

		if (_isETH) convertWethToEth(_isETH, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogBorrowWithMaxGas(address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_poolTokenAddress,
			_amt,
			_maxGasForMatching,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Withdraw ETH/ERC20_Token.
	 * @notice Withdraw a token from Morpho Compound.
	 * @param _tokenAddress The address of underlying token to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _poolTokenAddress The address of cToken to withdraw.(For ETH: cWETH address)
	 * @param _amount The amount of the token (in underlying) to withdraw. (For max: `uint256(-1)`)
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens withdrawed.
	 */
	function withdraw(
		address _tokenAddress,
		address _poolTokenAddress,
		uint256 _amount,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);
		bool _isETH = _tokenAddress == ethAddr;
		address _token = _isETH ? wethAddr : _tokenAddress;

		if (_amt == uint256(-1)) {
			(, , _amt) = morphoCompoundLens.getCurrentSupplyBalanceInOf(
				_poolTokenAddress,
				address(this)
			);
		}

		morphoCompound.withdraw(_poolTokenAddress, _amt);

		convertWethToEth(_isETH, TokenInterface(_token), _amt);

		setUint(_setId, _amt);

		_eventName = "LogWithdraw(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_poolTokenAddress,
			_amt,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Payback ETH/ERC20_Token.
	 * @notice Payback a token to Morpho Compound.
	 * @param _tokenAddress The address of underlying token to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _poolTokenAddress The address of cToken to payback.(For ETH: cWETH address)
	 * @param _amount The amount of the token (in underlying) to payback. (For max: `uint256(-1)`)
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens paid back.
	 */
	function payback(
		address _tokenAddress,
		address _poolTokenAddress,
		uint256 _amount,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		bool _isETH = _tokenAddress == ethAddr;
		uint256 _amt = getUint(_getId, _amount);

		TokenInterface _tokenContract = _isETH 
			? TokenInterface(wethAddr) 
			: TokenInterface(_tokenAddress);

		if (_amt == uint256(-1)) {
			uint256 _amtDSA = _isETH
				? address(this).balance
				: _tokenContract.balanceOf(address(this));

			(, , uint256 _amtDebt) = morphoCompoundLens
				.getCurrentBorrowBalanceInOf(_poolTokenAddress, address(this));

			_amt = _amtDSA <= _amtDebt ? _amtDSA : _amtDebt;
		}

		if (_isETH) convertEthToWeth(_isETH, _tokenContract, _amt);

		approve(_tokenContract, address(morphoCompound), _amt);

		morphoCompound.repay(_poolTokenAddress, address(this), _amt);

		setUint(_setId, _amt);

		_eventName = "LogPayback(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_poolTokenAddress,
			_amt,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Payback ETH/ERC20_Token.
	 * @notice Payback a token to Morpho Compound on behalf of a user.
	 * @param _tokenAddress The address of underlying token to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _poolTokenAddress The address of cToken to payback.(For ETH: cWETH address)
	 * @param _onBehalf The address of user who's debt to repay.
	 * @param _amount The amount of the token (in underlying) to payback. (For max: `uint256(-1)`)
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens paid back.
	 */
	function paybackOnBehalf(
		address _tokenAddress,
		address _poolTokenAddress,
		address _onBehalf,
		uint256 _amount,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		bool _isETH = _tokenAddress == ethAddr;
		uint256 _amt = getUint(_getId, _amount);
		
		TokenInterface _tokenContract = _isETH 
			? TokenInterface(wethAddr) 
			: TokenInterface(_tokenAddress);

		if (_amt == uint256(-1)) {
			uint256 _amtDSA = _isETH
				? address(this).balance
				: _tokenContract.balanceOf(address(this));

			(, , uint256 _amtDebt) = morphoCompoundLens
				.getCurrentBorrowBalanceInOf(_poolTokenAddress, _onBehalf);

			_amt = _amtDSA <= _amtDebt ? _amtDSA : _amtDebt;
		}

		if (_isETH) convertEthToWeth(_isETH, _tokenContract, _amt);

		approve(_tokenContract, address(morphoCompound), _amt);

		morphoCompound.repay(_poolTokenAddress, _onBehalf, _amt);

		setUint(_setId, _amt);

		_eventName = "LogPaybackOnBehalf(address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_poolTokenAddress,
			_onBehalf,
			_amt,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Claim rewards.
	 * @notice Claim rewards for the given assets from underlying protocol.
	 * @param _poolTokenAddresses The cToken addresses to claim rewards from..(For ETH: cToken address of WETH)
	 * @param _tradeForMorphoToken Whether or not to trade COMP tokens for MORPHO tokens.
	 */
	function claim(
		address[] calldata _poolTokenAddresses,
		bool _tradeForMorphoToken
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		morphoCompound.claimRewards(_poolTokenAddresses, _tradeForMorphoToken);

		_eventName = "LogClaimed(address[],bool)";
		_eventParam = abi.encode(_poolTokenAddresses, _tradeForMorphoToken);
	}
}

contract ConnectV2MorphoCompound is MorphoCompound {
	string public constant name = "Morpho-Compound-v1.0";
}
