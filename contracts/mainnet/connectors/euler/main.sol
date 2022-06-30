//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./helpers.sol";
import { Stores } from "../../common/stores.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract Euler is Helpers {
	using SafeERC20 for IERC20;

    /**
	 * @dev Deposit ETH/ERC20_Token.
	 * @notice Deposit a token to Euler for lending / collaterization.
     * @param subAccount Subaccount number
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

		eToken.deposit(subAccount, (_amt * eToken.decimals()));//0 for primary

        if (enableCollateral) {
            markets.enterMarket(subAccount, _token);
        }

		setUint(setId, _amt);

		_eventName = "LogDeposit(uint256,address,uint256,bool,uint256,uint256)";
		_eventParam = abi.encode(subAccount, token, _amt, enableCollateral, getId, setId);
	}

    /**
	 * @dev Withdraw ETH/ERC20_Token.
	 * @notice Withdraw deposited token Euler
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
        
        IEulerMarkets markets = IEulerMarkets(markets);
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
        uint256 _amt = getUint(getId, amt);//max value?

        bool isEth = token == ethAddr ? true : false;
        address _token = isEth ? wethAddr : token;

        IEulerDToken borrowedDToken = IEulerDToken(markets.underlyingToDToken(_token));
        borrowedDToken.borrow(subAccount, (amt * borrowedDToken.decimals()));

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
		IEulerDToken borrowedDToken = IEulerDToken(markets.underlyingToDToken(_token));

        if(isEth) convertEthToWeth(isEth, TokenInterface(_token), _amt);

		_amt = _amt == type(uint).max ? borrowedDToken.balanceOf(address(this)) : _amt;

		IERC20(_token).approve(EULER_MAINNET, _amt);
        borrowedDToken.repay(subAccount, (amt * borrowedDToken.decimals()));

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
		//should have some deposit first?
        bool isEth = token == ethAddr ? true : false;
        address _token = isEth ? wethAddr : token;
		IEulerEToken eToken = IEulerEToken(markets.underlyingToEToken(_token));

        if(isEth) convertEthToWeth(isEth, TokenInterface(_token), _amt);

        eToken.mint(subAccount, (amt * eToken.decimals()));

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
		address token,//eth
		uint256 amt,//max
		uint256 getId,//1
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

		_amt = _amt == type(uint).max ? dToken.balanceOf(address(this)) : _amt;

        if(isEth) convertEthToWeth(isEth, TokenInterface(_token), _amt);

        eToken.burn(subAccount, (amt * eToken.decimals()));

		setUint(setId, _amt);

		_eventName = "LogBurn(uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(subAccount, token, _amt, getId, setId);
    }

	/**
	 * @dev ETransfer ETH/ERC20_Token.
	 * @notice ETransfer deposits from account to another.
     * @param subAccount1 Subaccount from which deposit is transferred
	 * @param subAccount2 Subaccount to which deposit is transferred
	 * @param token The address of the token to etransfer.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to etransfer. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function eTransfer(
        uint256 subAccount1,
		uint256 subAccount2,
		address token,//eth
		uint256 amt,//max
		uint256 getId,//1
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

		_amt = _amt == type(uint).max ? eToken.balanceOf(address(this)) : _amt;

        if(isEth) convertEthToWeth(isEth, TokenInterface(_token), _amt);

        eToken.transfer(msg.sender, (amt * eToken.decimals()));//update

		setUint(setId, _amt);

		_eventName = "LogETransfer(uint256,uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(subAccount1, subAccount2, token, _amt, getId, setId);
    }

	/**
	 * @dev DTransfer ETH/ERC20_Token.
	 * @notice DTransfer deposits from account to another.
     * @param subAccount1 Subaccount from which debt is transferred
	 * @param subAccount2 Subaccount to which debt is transferred
	 * @param token The address of the token to dtransfer.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to dtransfer. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function dTransfer(
        uint256 subAccount1,
		uint256 subAccount2,
		address token,//eth
		uint256 amt,//max
		uint256 getId,//1
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
        uint256 _amt = getUint(getId, amt);

        bool isEth = token == ethAddr ? true : false;
        address _token = isEth ? wethAddr : token;

		IEulerEToken dToken = IEulerEToken(markets.underlyingToDToken(_token));

		_amt = _amt == type(uint).max ? dToken.balanceOf(address(this)) : _amt;

        if(isEth) convertEthToWeth(isEth, TokenInterface(_token), _amt);

        dToken.transfer(msg.sender, (amt * dToken.decimals()));//update

		setUint(setId, _amt);

		_eventName = "LogDTransfer(uint256,uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(subAccount1, subAccount2, token, _amt, getId, setId);
    }
}