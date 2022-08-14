//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./helpers.sol";
import { Stores } from "../../common/stores.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract Euler is Helpers {
	using SafeERC20 for IERC20;

	/**
	 * @dev Deposit ETH/ERC20_Token.
	 * @notice Deposit a token to Euler for lending / collaterization.
	 * @param subAccount Sub-account Id (0 for primary and 1 - 255 for sub-account)
	 * @param token The address of the token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param enableCollateral True for entering the market
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function deposit(
		uint256 subAccount,
		address token,
		uint256 amt,
		bool enableCollateral,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(_token);

		if (isEth) {
			_amt = _amt == uint256(-1) ? address(this).balance : _amt;
			convertEthToWeth(isEth, tokenContract, _amt);
		} else {
			_amt = _amt == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: _amt;
		}

		approve(tokenContract, EULER_MAINNET, _amt);

		IEulerEToken eToken = IEulerEToken(markets.underlyingToEToken(_token));
		eToken.deposit(subAccount, _amt);

		if (enableCollateral) {
			markets.enterMarket(subAccount, _token);
		}
		setUint(setId, _amt);

		_eventName = "LogDeposit(uint256,address,uint256,bool,uint256,uint256)";
		_eventParam = abi.encode(
			subAccount,
			token,
			_amt,
			enableCollateral,
			getId,
			setId
		);
	}

	/**
	 * @dev Withdraw ETH/ERC20_Token.
	 * @notice Withdraw deposited token and earned interest from Euler
	 * @param subAccount Subaccount number
	 * @param token The address of the token to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdraw(
		uint256 subAccount,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(_token);
		IEulerEToken eToken = IEulerEToken(markets.underlyingToEToken(_token));

		address _subAccount = getSubAccount(address(this), subAccount);
		_amt = _amt == uint256(-1) ?  eToken.balanceOfUnderlying(_subAccount) : _amt;
		uint256 initialBal = tokenContract.balanceOf(address(this));

		eToken.withdraw(subAccount, _amt);

		uint256 finalBal = tokenContract.balanceOf(address(this));
		_amt = finalBal - initialBal;

		convertWethToEth(isEth, tokenContract, _amt);

		setUint(setId, _amt);

		_eventName = "LogWithdraw(uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(subAccount, token, _amt, getId, setId);
	}

	/**
	 * @dev Borrow ETH/ERC20_Token.
	 * @notice Borrow a token from Euler
	 * @param subAccount Subaccount number
	 * @param token The address of the token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to borrow.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function borrow(
		uint256 subAccount,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		bool isEth = token == ethAddr ? true : false;
		address _token = isEth ? wethAddr : token;

		IEulerDToken borrowedDToken = IEulerDToken(
			markets.underlyingToDToken(_token)
		);
		borrowedDToken.borrow(subAccount, _amt);

		convertWethToEth(isEth, TokenInterface(_token), _amt);

		setUint(setId, _amt);

		_eventName = "LogBorrow(uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(subAccount, token, _amt, getId, setId);
	}

	/**
	 * @dev Repay ETH/ERC20_Token.
	 * @notice Repay a token from Euler
	 * @param subAccount Subaccount number
	 * @param token The address of the token to repay.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to repay. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function repay(
		uint256 subAccount,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		IEulerDToken borrowedDToken = IEulerDToken(
			markets.underlyingToDToken(_token)
		);

		address _subAccount = getSubAccount(address(this), subAccount);
		_amt = _amt == uint256(-1) ? borrowedDToken.balanceOf(_subAccount) : _amt;
		if (isEth) {
			convertEthToWeth(isEth, TokenInterface(_token), _amt);
		}

		approve(TokenInterface(_token), EULER_MAINNET, _amt);
		borrowedDToken.repay(subAccount, _amt);

		setUint(setId, _amt);

		_eventName = "LogRepay(uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(subAccount, token, _amt, getId, setId);
	}

	/**
	 * @dev Mint ETH/ERC20_Token.
	 * @notice Mint a token from Euler. Mint creates an equal amount of deposits and debts. (self-borrow)
	 * @param subAccount Subaccount number
	 * @param token The address of the token to mint.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to mint.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function mint(
		uint256 subAccount,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		bool isEth = token == ethAddr ? true : false;
		address _token = isEth ? wethAddr : token;
		IEulerEToken eToken = IEulerEToken(markets.underlyingToEToken(_token));

		if (isEth) convertEthToWeth(isEth, TokenInterface(_token), _amt);

		eToken.mint(subAccount, _amt);

		setUint(setId, _amt);

		_eventName = "LogMint(uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(subAccount, token, _amt, getId, setId);
	}

	/**
	 * @dev Burn ETH/ERC20_Token.
	 * @notice Burn a token from Euler. Burn removes equal amount of deposits and debts.
	 * @param subAccount Subaccount number
	 * @param token The address of the token to burn.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to burn.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function burn(
		uint256 subAccount,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		bool isEth = token == ethAddr ? true : false;
		address _token = isEth ? wethAddr : token;

		IEulerDToken dToken = IEulerDToken(markets.underlyingToDToken(_token));
		IEulerEToken eToken = IEulerEToken(markets.underlyingToEToken(_token));

		address _subAccount = getSubAccount(address(this), subAccount);

		if(_amt == uint256(-1)) {

			uint256 _eTokenBalance = eToken.balanceOfUnderlying(_subAccount);
			uint256 _dTokenBalance = dToken.balanceOf(_subAccount);

			_amt = _eTokenBalance <= _dTokenBalance ? _eTokenBalance : _dTokenBalance;
		}

		if (isEth) convertEthToWeth(isEth, TokenInterface(_token), _amt);

		eToken.burn(subAccount, _amt);

		setUint(setId, _amt);

		_eventName = "LogBurn(uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(subAccount, token, _amt, getId, setId);
	}

	/**
	 * @dev ETransfer ETH/ERC20_Token.
	 * @notice ETransfer deposits from one sub-account to another.
	 * @param subAccountFrom subAccount from which deposit is transferred
	 * @param subAccountTo subAccount to which deposit is transferred
	 * @param token The address of the token to etransfer.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to etransfer. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function eTransfer(
		uint256 subAccountFrom,
		uint256 subAccountTo,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		bool isEth = token == ethAddr ? true : false;
		address _token = isEth ? wethAddr : token;

		IEulerEToken eToken = IEulerEToken(markets.underlyingToEToken(_token));

		address _subAccountFromAddr = getSubAccount(address(this), subAccountFrom);
		address _subAccountToAddr = getSubAccount(address(this), subAccountTo);

		_amt = _amt == uint256(-1)
			? eToken.balanceOf(_subAccountFromAddr)
			: _amt;

		if (isEth) convertEthToWeth(isEth, TokenInterface(_token), _amt);

		eToken.transferFrom(_subAccountFromAddr, _subAccountToAddr, _amt);

		setUint(setId, _amt);

		_eventName = "LogETransfer(uint256,uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			subAccountFrom,
			subAccountTo,
			token,
			_amt,
			getId,
			setId
		);
	}

	/**
	 * @dev DTransfer ETH/ERC20_Token.
	 * @notice DTransfer deposits from one sub-account to another.
	 * @param subAccountFrom subAccount from which debt is transferred
	 * @param subAccountTo subAccount to which debt is transferred
	 * @param token The address of the token to dtransfer.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to dtransfer. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function dTransfer(
		uint256 subAccountFrom,
		uint256 subAccountTo,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		bool isEth = token == ethAddr ? true : false;
		address _token = isEth ? wethAddr : token;

		IEulerDToken dToken = IEulerDToken(markets.underlyingToDToken(_token));

		address _subAccountFromAddr = getSubAccount(address(this), subAccountFrom);
		address _subAccountToAddr = getSubAccount(address(this), subAccountTo);

		_amt = _amt == uint256(-1)
			? dToken.balanceOf(_subAccountFromAddr)
			: _amt;

		if (isEth) convertEthToWeth(isEth, TokenInterface(_token), _amt);

		dToken.transferFrom(_subAccountFromAddr, _subAccountToAddr, _amt);

		setUint(setId, _amt);

		_eventName = "LogDTransfer(uint256,uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			subAccountFrom,
			subAccountTo,
			token,
			_amt,
			getId,
			setId
		);
	}

	/**
	 * @dev Approve Spender's debt.
	 * @notice Approve sender to send debt.
	 * @param subAccountId Subaccount id of receiver
	 * @param debtSender Address of sender
	 * @param token The address of the token.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function approveSpenderDebt(
		uint256 subAccountId,
		address debtSender,
		address token,
		uint256 amt,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		IEulerDToken dToken = IEulerDToken(markets.underlyingToDToken(_token));

		dToken.approveDebt(subAccountId, debtSender, amt);

		setUint(setId, amt);

		_eventName = "LogApproveSpenderDebt(uint256,address,address,uint256,uint256)";
		_eventParam = abi.encode(subAccountId, debtSender, token, amt, setId);
	}

	/**
	 * @dev Enter Market.
	 * @notice Enter Market.
	 * @param subAccountId Subaccount number
	 * @param tokens Array of new token markets to be entered
	 */
	function enterMarket(uint256 subAccountId, address[] memory tokens)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _length = tokens.length;
		require(_length > 0, "0-markets-not-allowed");

		for (uint256 i = 0; i < _length; i++) {
			address _token = tokens[i] == ethAddr ? wethAddr : tokens[i];
			markets.enterMarket(subAccountId, _token);
		}

		_eventName = "LogEnterMarket(uint256,address[])";
		_eventParam = abi.encode(subAccountId, tokens);
	}

	/**
	 * @dev Exit Market.
	 * @notice Exit Market.
	 * @param subAccountId Subaccount number
	 * @param token token address
	 */
	function exitMarket(uint256 subAccountId, address token)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		address _token = token == ethAddr ? wethAddr : token;
		markets.exitMarket(subAccountId, _token);

		_eventName = "LogExitMarket(uint256,address)";
		_eventParam = abi.encode(subAccountId, token);
	}
}

contract ConnectV2Euler is Euler {
	string public constant name = "Euler-v1.0";
}
