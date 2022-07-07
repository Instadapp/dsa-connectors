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
		eToken.deposit(subAccount, _amt); //0 for primary

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
	 * @param amt The amount of the token to borrow. (For max: `uint256(-1)`)
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

		bool isEth = token == ethAddr ? true : false;

		address _token = isEth ? wethAddr : token;
		IEulerDToken borrowedDToken = IEulerDToken(
			markets.underlyingToDToken(_token)
		);

		if (isEth) convertEthToWeth(isEth, TokenInterface(_token), _amt);

		_amt = _amt == type(uint256).max
			? borrowedDToken.balanceOf(address(this))
			: _amt;

		TokenInterface(_token).approve(EULER_MAINNET, _amt);
		borrowedDToken.repay(subAccount, amt);

		setUint(setId, _amt);

		_eventName = "LogRepay(uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(subAccount, token, _amt, getId, setId);
	}

	/**
	 * @dev Mint ETH/ERC20_Token.
	 * @notice Mint a token from Euler. Maint creates equal amount of deposits and debts.
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

		eToken.mint(subAccount, amt);

		setUint(setId, _amt);

		_eventName = "LogMint(uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(subAccount, token, _amt, getId, setId);
	}

	/**
	 * @dev Burn ETH/ERC20_Token.
	 * @notice Burn a token from Euler. Burn removes equal amount of deposits and debts.
	 * @param subAccount Subaccount number
	 * @param token The address of the token to burn.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to burn. (For max: `uint256(-1)`)
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

		_amt = _amt == type(uint256).max
			? dToken.balanceOf(address(this))
			: _amt;

		if (isEth) convertEthToWeth(isEth, TokenInterface(_token), _amt);

		eToken.burn(subAccount, amt);

		setUint(setId, _amt);

		_eventName = "LogBurn(uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(subAccount, token, _amt, getId, setId);
	}

	/**
	 * @dev ETransfer ETH/ERC20_Token.
	 * @notice ETransfer deposits from account to another.
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

		_amt = _amt == type(uint256).max
			? eToken.balanceOf(address(this))
			: _amt;

		if (isEth) convertEthToWeth(isEth, TokenInterface(_token), _amt);

		address _subAccountToAddr = getSubAccount(address(this), subAccountTo);

		eToken.transfer(_subAccountToAddr, amt);

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
	 * @notice DTransfer deposits from account to another.
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

		_amt = _amt == type(uint256).max
			? dToken.balanceOf(address(this))
			: _amt;

		if (isEth) convertEthToWeth(isEth, TokenInterface(_token), _amt);

		address _subAccountToAddr = getSubAccount(address(this), subAccountTo);
		dToken.transfer(_subAccountToAddr, amt);

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
	 * @dev Approve debt.
	 * @notice Approves receiver to take debt.
	 * @param subAccountId Subaccount number
	 * @param debtReceiver Address of receiver
	 * @param token The address of the token to mint.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to mint.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function approveDebt(
		uint256 subAccountId,
		address debtReceiver,
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

		IEulerDToken dToken = IEulerDToken(markets.underlyingToDToken(_token));
		_amt = _amt == type(uint256).max
			? dToken.balanceOf(address(this))
			: _amt;

		dToken.approveDebt(subAccountId, debtReceiver, _amt);

		setUint(setId, _amt);

		_eventName = "LogApproveDebt(uint256,address,address,uint256)";
		_eventParam = abi.encode(subAccountId, debtReceiver, token, amt);
	}

	struct swapHelper {
		address _sellAddr;
		address _buyAddr;
		uint256 _buyDec;
		uint256 _sellDec;
		uint256 _sellAmt18;
		uint256 _slippageAmt;
	}

	struct swapParams {
		uint256 subAccountFrom;
		uint256 subAccountTo;
		address buyAddr;
		address sellAddr;
		uint256 sellAmt;
		uint256 unitAmt;
		bytes callData;
	}

	/**
	 * @dev Swap.
	 * @notice Executes swap.
	 * @param params swapParams struct
	 */
	function swap(swapParams memory params)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		swapHelper memory helperParams;

		helperParams._sellAddr = params.sellAddr == ethAddr
			? wethAddr
			: params.sellAddr;
		helperParams._buyAddr = params.sellAddr == ethAddr
			? wethAddr
			: params.buyAddr;

		TokenInterface sellToken = TokenInterface(helperParams._sellAddr);
		TokenInterface buyToken = TokenInterface(helperParams._buyAddr);

		approve(sellToken, address(swapExec), params.sellAmt);

		(helperParams._buyDec, helperParams._sellDec) = getTokensDec(
			buyToken,
			sellToken
		);
		helperParams._sellAmt18 = convertTo18(
			helperParams._sellDec,
			params.sellAmt
		);
		helperParams._slippageAmt = convert18ToDec(
			helperParams._buyDec,
			wmul(params.unitAmt, helperParams._sellAmt18)
		);

		IEulerSwap.Swap1InchParams memory oneInchParams = IEulerSwap
			.Swap1InchParams({
				subAccountIdIn: params.subAccountFrom,
				subAccountIdOut: params.subAccountTo,
				underlyingIn: helperParams._sellAddr,
				underlyingOut: helperParams._buyAddr,
				amount: params.sellAmt,
				amountOutMinimum: helperParams._slippageAmt,
				payload: params.callData
			});

		swapExec.swap1Inch(oneInchParams);

		if (!checkIfEnteredMarket(helperParams._buyAddr)) {
			markets.enterMarket(params.subAccountTo, helperParams._buyAddr);
		}

		_eventName = "LogSwap(uint256,uint256,address,address,uint256,uint256,bytes)";
		_eventParam = abi.encode(
			params.subAccountFrom,
			params.subAccountTo,
			params.buyAddr,
			params.sellAddr,
			params.sellAmt,
			params.unitAmt,
			params.callData
		);
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
			bool isEth = tokens[i] == ethAddr;
			address _token = isEth ? wethAddr : tokens[i];

			IEulerEToken eToken = IEulerEToken(
				markets.underlyingToEToken(_token)
			);
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
		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		markets.exitMarket(subAccountId, _token);

		_eventName = "LogExitMarket(uint256,address)";
		_eventParam = abi.encode(subAccountId, token);
	}
}

contract ConnectV2Euler is Euler {
	string public constant name = "Euler-v1.0";
}
