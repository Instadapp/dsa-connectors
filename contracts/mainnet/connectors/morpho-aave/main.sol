//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./helpers.sol";
import "./events.sol";

abstract contract MorphoAave is Helpers, Events {
	/**
	 * @dev Deposit ETH/ERC20_Token.
	 * @notice Deposit a token to Morpho Aave for lending / collaterization.
	 * @param _tokenAddress The address of underlying token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _poolTokenAddress The address of aToken to deposit.(For ETH: aWETH address)
	 * @param _amount The amount of the token (in underlying) to deposit. (For max: `uint256(-1)`)
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function deposit(
		address _tokenAddress,
		address _poolTokenAddress,
		uint256 _amount,
		// uint256 _maxGasForMatching, // optional
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

		approve(_tokenContract, address(morphoAave), _amt);

		morphoAave.supply(_poolTokenAddress, address(this), _amt);

		setUint(_setId, _amt);

		_eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_poolTokenAddress,
			_amt,
			// _maxGasForMatching,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Borrow ETH/ERC20_Token.
	 * @notice Borrow a token from Morpho Aave.
	 * @param _tokenAddress The address of underlying token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _poolTokenAddress The address of aToken to borrow.(For ETH: aWETH address)
	 * @param _amount The amount of the token (in underlying) to borrow.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function borrow(
		address _tokenAddress,
		address _poolTokenAddress,
		uint256 _amount,
		// uint256 _maxGasForMatching,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);

		bool _isETH = _tokenAddress == ethAddr;

		morphoAave.borrow(_poolTokenAddress, _amt);

		if (_isETH) convertWethToEth(_isETH, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogBorrow(bool,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_isETH,
			_poolTokenAddress,
			_amt,
			// _maxGasForMatching,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Withdraw ETH/ERC20_Token.
	 * @notice Withdraw a token from Morpho Aave.
	 * @param _tokenAddress The address of underlying token to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _poolTokenAddress The address of aToken to withdraw.(For ETH: aWETH address)
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

		if (_amt == uint256(-1))
			(, , , _amt) = morphoAaveLens._getCurrentSupplyBalanceInOf(
				_poolTokenAddress,
				address(this)
			);

		morphoAave.withdraw(_poolTokenAddress, _amt);

		convertWethToEth(_isETH, TokenInterface(_token), _amt);

		setUint(_setId, _amt);

		_eventName = "LogWithdraw(bool,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_isETH,
			_poolTokenAddress,
			_amt,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Payback ETH/ERC20_Token.
	 * @notice Payback a token to Morpho Aave.
	 * @param _tokenAddress The address of underlying token to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _poolTokenAddress The address of aToken to payback.(For ETH: aWETH address)
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
		address _token = _isETH ? wethAddr : _tokenAddress;

		if (_amt == uint256(-1)) {
			(, , , _amt) = morphoAaveLens._getCurrentBorrowBalanceInOf(
				_poolTokenAddress,
				address(this)
			);
		}

		if (_isETH) convertEthToWeth(_isETH, TokenInterface(_token), _amt);

		approve(TokenInterface(_token), address(morphoAave), _amt);

		morphoAave.repay(_poolTokenAddress, address(this), _amt);

		setUint(_setId, _amt);

		_eventName = "LogPayback(bool,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_isETH,
			_poolTokenAddress,
			_amt,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Claim rewards.
	 * @notice Claim rewards for the given assets from underlying protocol.
	 * @param _poolTokenAddresses The assets to claim rewards from (aToken or variable debt token).(For ETH: aToken or variable debt token address of WETH)
	 * @param _tradeForMorphoToken Whether or not to trade reward tokens for MORPHO tokens.
	 */
	function claim(
		address[] calldata _poolTokenAddresses, //todo: eth will be claimed as weth currently?
		bool _tradeForMorphoToken
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		morphoAave.claimRewards(_poolTokenAddresses, _tradeForMorphoToken);

		_eventName = "LogClaimed(address[],bool)";
		_eventParam = abi.encode(_poolTokenAddresses, _tradeForMorphoToken);
	}
}

contract ConnectV2MorphoAave is MorphoAave {
	string public constant name = "Morpho-Aave-v1.0";
}
