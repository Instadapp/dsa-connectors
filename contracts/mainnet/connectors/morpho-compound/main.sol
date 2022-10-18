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
	 * @param _poolTokenAddress The address of cToken to deposit.(For ETH: cETH address)
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
		(
			TokenInterface _tokenContract,
			uint256 _amt
		) = _performEthToWethConversion(_tokenAddress, _amount, _getId);

		approve(_tokenContract, address(MORPHO_COMPOUND), _amt);

		MORPHO_COMPOUND.supply(_poolTokenAddress, address(this), _amt);

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
	 * @param _poolTokenAddress The address of cToken to deposit.(For ETH: cETH address).
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
		(
			TokenInterface _tokenContract,
			uint256 _amt
		) = _performEthToWethConversion(_tokenAddress, _amount, _getId);

		approve(_tokenContract, address(MORPHO_COMPOUND), _amt);

		MORPHO_COMPOUND.supply(
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
	 * @param _poolTokenAddress The address of cToken to deposit.(For ETH: cETH address)
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
		(
			TokenInterface _tokenContract,
			uint256 _amt
		) = _performEthToWethConversion(_tokenAddress, _amount, _getId);

		approve(_tokenContract, address(MORPHO_COMPOUND), _amt);

		MORPHO_COMPOUND.supply(_poolTokenAddress, _onBehalf, _amt);

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
	 * @param _poolTokenAddress The address of cToken to borrow.(For ETH: cETH address)
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

		MORPHO_COMPOUND.borrow(_poolTokenAddress, _amt);

		convertWethToEth(_tokenAddress == ethAddr, TokenInterface(wethAddr), _amt);

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
	 * @param _poolTokenAddress The address of cToken to borrow.(For ETH: cETH address)
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

		MORPHO_COMPOUND.borrow(_poolTokenAddress, _amt, _maxGasForMatching);

		convertWethToEth(_tokenAddress == ethAddr, TokenInterface(wethAddr), _amt);

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
	 * @param _poolTokenAddress The address of cToken to withdraw.(For ETH: cETH address)
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

		if (_amt == uint256(-1)) {
			(, , _amt) = MORPHO_COMPOUND_LENS.getCurrentSupplyBalanceInOf(
				_poolTokenAddress,
				address(this)
			);
		}

		MORPHO_COMPOUND.withdraw(_poolTokenAddress, _amt);

		convertWethToEth(_isETH, TokenInterface(wethAddr), _amt);

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
	 * @param _poolTokenAddress The address of cToken to payback.(For ETH: cETH address)
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

			(, , uint256 _amtDebt) = MORPHO_COMPOUND_LENS
				.getCurrentBorrowBalanceInOf(_poolTokenAddress, address(this));

			_amt = _amtDSA < _amtDebt ? _amtDSA : _amtDebt;
		}

		convertEthToWeth(_isETH, _tokenContract, _amt);

		approve(_tokenContract, address(MORPHO_COMPOUND), _amt);

		MORPHO_COMPOUND.repay(_poolTokenAddress, address(this), _amt);

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
	 * @param _poolTokenAddress The address of cToken to payback.(For ETH: cETH address)
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

			(, , uint256 _amtDebt) = MORPHO_COMPOUND_LENS
				.getCurrentBorrowBalanceInOf(_poolTokenAddress, _onBehalf);

			_amt = _amtDSA < _amtDebt ? _amtDSA : _amtDebt;
		}

		convertEthToWeth(_isETH, _tokenContract, _amt);

		approve(_tokenContract, address(MORPHO_COMPOUND), _amt);

		MORPHO_COMPOUND.repay(_poolTokenAddress, _onBehalf, _amt);

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
}

contract ConnectV2MorphoCompound is MorphoCompound {
	string public constant name = "Morpho-Compound-v1.0";
}
