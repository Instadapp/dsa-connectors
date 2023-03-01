//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./helpers.sol";
import "./events.sol";

abstract contract MorphoAaveV3 is Helpers, Events {
	/**
	 * @dev Deposit ETH/ERC20_Token.
	 * @notice Deposit a token to Morpho Aave for lending.
	 * @param _tokenAddress The address of underlying token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to deposit. (For max: `uint256(-1)`)
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function deposit(
		address _tokenAddress,
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

		approve(_tokenContract, address(MORPHO_AAVE_V3), _amt);

		MORPHO_AAVE_V3.supply(address(_tokenContract), _amt, address(this), max_iteration);

		setUint(_setId, _amt);

		_eventName = "LogDeposit(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Deposit ETH/ERC20_Token.
	 * @notice Deposit a token to Morpho Aave for lending.
	 * @param _tokenAddress The address of underlying token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to deposit. (For max: `uint256(-1)`)
	 * @param _maxIteration The maximum number of iterations allowed during the matching process.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function depositWithMaxIterations(
		address _tokenAddress,
		uint256 _amount,
		uint256 _maxIteration,
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

		approve(_tokenContract, address(MORPHO_AAVE_V3), _amt);

		MORPHO_AAVE_V3.supply(address(_tokenContract), _amt, address(this), _maxIteration);

		setUint(_setId, _amt);

		_eventName = "LogDepositWithMaxIterations(address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_maxIteration,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Deposit ETH/ERC20_Token on behalf of a user.
	 * @notice Deposit a token to Morpho Aave for lending on behalf of a user.
	 * @param _tokenAddress The address of underlying token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to deposit. (For max: `uint256(-1)`)
	 * @param _onBehalf The address of user on behalf of whom we want to deposit.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function depositOnBehalf(
		address _tokenAddress,
		uint256 _amount,
		address _onBehalf,
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

		approve(_tokenContract, address(MORPHO_AAVE_V3), _amt);

		MORPHO_AAVE_V3.supply(address(_tokenContract), _amt, _onBehalf, max_iteration);

		setUint(_setId, _amt);

		_eventName = "LogDepositOnBehalf(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_onBehalf,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Deposit ETH/ERC20_Token on behalf of a user.
	 * @notice Deposit a token to Morpho Aave for lending on behalf of a user with max iterations.
	 * @param _tokenAddress The address of underlying token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to deposit. (For max: `uint256(-1)`)
	 * @param _onBehalf The address of user on behalf of whom we want to deposit.
	 * @param _maxIteration The maximum number of iterations allowed during the matching process.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function depositOnBehalfWithMaxIterations (
		address _tokenAddress,
		uint256 _amount,
		address _onBehalf,
		uint256 _maxIteration,
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

		approve(_tokenContract, address(MORPHO_AAVE_V3), _amt);

		MORPHO_AAVE_V3.supply(address(_tokenContract), _amt, _onBehalf, _maxIteration);

		setUint(_setId, _amt);

		_eventName = "LogDepositOnBehalfWithMaxIterations(address,uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_onBehalf,
			_maxIteration,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Deposit ETH/ERC20_Token on behalf of a user.
	 * @notice Deposit a token to Morpho Aave for lending / collaterization.
	 * @param _tokenAddress The address of underlying token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to deposit. (For max: `uint256(-1)`)
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function depositCollateral(
		address _tokenAddress,
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

		approve(_tokenContract, address(MORPHO_AAVE_V3), _amt);

		MORPHO_AAVE_V3.supplyCollateral(address(_tokenContract), _amt, address(this));

		setUint(_setId, _amt);

		_eventName = "LogDepositCollateral(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Deposit ETH/ERC20_Token on behalf of a user.
	 * @notice Deposit a token to Morpho Aave for lending / collaterization on behalf of a user.
	 * @param _tokenAddress The address of underlying token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to deposit. (For max: `uint256(-1)`)
	 * @param _onBehalf The address of user on behalf to deposit.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens deposited.
	 */
	function depositCollateralOnBehalf(
		address _tokenAddress,
		uint256 _amount,
		address _onBehalf,
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

		approve(_tokenContract, address(MORPHO_AAVE_V3), _amt);

		MORPHO_AAVE_V3.supplyCollateral(address(_tokenContract), _amt, _onBehalf);

		setUint(_setId, _amt);

		_eventName = "LogDepositCollateralOnBehalf(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_onBehalf,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Borrow ETH/ERC20_Token.
	 * @notice Borrow a token from Morpho Aave.
	 * @param _tokenAddress The address of underlying token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to borrow.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function borrow(
		address _tokenAddress,
		uint256 _amount,
		address _receiver,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);

		MORPHO_AAVE_V3.borrow(_tokenAddress, _amt, address(this), _receiver, max_iteration);

		convertWethToEth(_tokenAddress == ethAddr, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogBorrow(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_receiver,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Borrow ETH/ERC20_Token.
	 * @notice Borrow a token from Morpho Aave V3.
	 * @param _tokenAddress The address of underlying token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to borrow.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function borrowOnBehalf(
		address _tokenAddress,
		uint256 _amount,
		address _onBehalf,
		address _receiver,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);

		address _token = _tokenAddress == ethAddr ? wethAddr : _tokenAddress;
		MORPHO_AAVE_V3.borrow(_token, _amt, _onBehalf, _receiver, max_iteration);

		convertWethToEth(_tokenAddress == ethAddr, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogBorrowOnBehalf(address,uint256,addresss,address,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_onBehalf,
			_receiver,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Borrow ETH/ERC20_Token.
	 * @notice Borrow a token from Morpho Aave.
	 * @param _tokenAddress The address of underlying token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to borrow.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function borrowWithMaxIterations(
		address _tokenAddress,
		uint256 _amount,
		address _receiver,
		uint256 _maxIteration,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);
		address _token = _tokenAddress == ethAddr ? wethAddr : _tokenAddress;
		MORPHO_AAVE_V3.borrow(_token, _amt, address(this), _receiver, _maxIteration);

		convertWethToEth(_tokenAddress == ethAddr, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogBorrowWithMaxIterations(address,uint256,addresss,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_receiver,
			_maxIteration,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Borrow ETH/ERC20_Token.
	 * @notice Borrow a token from Morpho Aave.
	 * @param _tokenAddress The address of underlying token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to borrow.
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens borrowed.
	 */
	function borrowOnBehalfWithMaxIterations (
		address _tokenAddress,
		uint256 _amount,
		address _onBehalf,
		address _receiver,
		uint256 _maxIteration,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);
		address _token = _tokenAddress == ethAddr ? wethAddr : _tokenAddress;
		MORPHO_AAVE_V3.borrow(_token, _amt, _onBehalf, _receiver, _maxIteration);

		convertWethToEth(_tokenAddress == ethAddr, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogBorrowOnBehalfWithMaxIterations(address,uint256,addresss,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_onBehalf,
			_receiver,
			_maxIteration,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Withdraw ETH/ERC20_Token.
	 * @notice Withdraw a token from Morpho Aave.
	 * @param _tokenAddress The address of underlying token to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to withdraw. (For max: `uint256(-1)`)
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens withdrawed.
	 */
	function withdraw(
		address _tokenAddress,
		uint256 _amount,
		address _receiver,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);
		MORPHO_AAVE_V3.withdraw(_tokenAddress, _amt, address(this), _receiver, max_iteration);

		convertWethToEth(_tokenAddress == ethAddr, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogWithdraw(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_receiver,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Withdraw ETH/ERC20_Token.
	 * @notice Withdraw a token from Morpho Aave.
	 * @param _tokenAddress The address of underlying token to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to withdraw. (For max: `uint256(-1)`)
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens withdrawed.
	 */
	function withdrawOnBehalf(
		address _tokenAddress,
		uint256 _amount,
		address _onBehalf,
		address _receiver,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);
		MORPHO_AAVE_V3.withdraw(_tokenAddress, _amt, _onBehalf, _receiver, max_iteration);

		convertWethToEth(_tokenAddress == ethAddr, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogWithdrawOnBehalf(address,uint256,address,address,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_onBehalf,
			_receiver,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Withdraw ETH/ERC20_Token.
	 * @notice Withdraw a token from Morpho Aave.
	 * @param _tokenAddress The address of underlying token to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to withdraw. (For max: `uint256(-1)`)
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens withdrawed.
	 */
	function withdrawWithMaxIterations(
		address _tokenAddress,
		uint256 _amount,
		address _onBehalf,
		address _receiver,
		uint256 _maxIteration,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);

		MORPHO_AAVE_V3.withdraw(_tokenAddress, _amt, _onBehalf, _receiver, _maxIteration);

		convertWethToEth(_tokenAddress == ethAddr, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogWithdrawWithMaxIterations(address,uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_receiver,
			_maxIteration,
			_getId,
			_setId
		);
	}

	function withdrawCollateral(
		address _tokenAddress,
		uint256 _amount,
		address _receiver,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);

		MORPHO_AAVE_V3.withdrawCollateral(_tokenAddress, _amt, address(this), _receiver);

		convertWethToEth(_tokenAddress == ethAddr, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogWithdrawCollateral(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_receiver,
			_getId,
			_setId
		);
	}

	function withdrawCollateralOnBehalf(
		address _tokenAddress,
		uint256 _amount,
		address _onBehalf,
		address _receiver,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(_getId, _amount);
		MORPHO_AAVE_V3.withdrawCollateral(_tokenAddress, _amt, _onBehalf, _receiver);
		convertWethToEth(_tokenAddress == ethAddr, TokenInterface(wethAddr), _amt);

		setUint(_setId, _amt);

		_eventName = "LogWithdrawCollateralOnBehalf(address,uint256,address,address,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_onBehalf,
			_receiver,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Payback ETH/ERC20_Token.
	 * @notice Payback a token to Morpho Aave.
	 * @param _tokenAddress The address of underlying token to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _amount The amount of the token (in underlying) to payback. (For max: `uint256(-1)`)
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens paid back.
	 */
	function payback(
		address _tokenAddress,
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
			_amt = _isETH
				? address(this).balance
				: _tokenContract.balanceOf(address(this));
		}

		convertEthToWeth(_isETH, _tokenContract, _amt);

		approve(_tokenContract, address(MORPHO_AAVE_V3), _amt);

		MORPHO_AAVE_V3.repay(_tokenAddress, _amt, address(this));

		setUint(_setId, _amt);

		_eventName = "LogPayback(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_getId,
			_setId
		);
	}

	/**
	 * @dev Payback ETH/ERC20_Token.
	 * @notice Payback a token to Morpho Aave.
	 * @param _tokenAddress The address of underlying token to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param _onBehalf The address of user who's debt to repay.
	 * @param _amount The amount of the token (in underlying) to payback. (For max: `uint256(-1)`)
	 * @param _getId ID to retrieve amt.
	 * @param _setId ID stores the amount of tokens paid back.
	 */
	function paybackOnBehalf(
		address _tokenAddress,
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
			_amt = _isETH
				? address(this).balance
				: _tokenContract.balanceOf(address(this));
		}

		convertEthToWeth(_isETH, _tokenContract, _amt);

		approve(_tokenContract, address(MORPHO_AAVE_V3), _amt);

		MORPHO_AAVE_V3.repay(_tokenAddress, _amt, _onBehalf);

		setUint(_setId, _amt);

		_eventName = "LogPaybackOnBehalf(address,uint256,address,uint256,uint256)";
		_eventParam = abi.encode(
			_tokenAddress,
			_amt,
			_onBehalf,
			_getId,
			_setId
		);
	}
}

contract ConnectV3MorphoAaveV3 is MorphoAaveV3 {
	string public constant name = "Morpho-AaveV3-v1.0";
}
