pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Trader-Joe.
 * @dev Lending & Borrowing.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { JAVAXInterface, JTokenInterface } from "./interface.sol";
import "hardhat/console.sol";

abstract contract TraderJoeResolver is Events, Helpers {
    /**
     * @dev Deposit AVAX/ERC20_Token.
     * @notice Deposit a token to TraderJoe for lending / collaterization.
     * @param token The address of the token to deposit. (For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param jToken The address of the corresponding jToken.
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function depositRaw(
        address token,
        address jToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        
        uint _amt = getUint(getId, amt);
        
        require(token != address(0) && jToken != address(0), "invalid token/jToken address");

        enterMarket(jToken);
        
        if (token == avaxAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
           
            JAVAXInterface(jToken).mintNative{value: _amt}();
            
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
           
            approve(tokenContract, jToken, _amt);
            
            require(JTokenInterface(jToken).mint(_amt) == 0, "deposit-failed");
            
        }
        
        setUint(setId, _amt);

        _eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
        
        _eventParam = abi.encode(token, jToken, _amt, getId, setId);
        
    }

    /**
     * @dev Deposit AVAX/ERC20_Token using token and jToken addresses.
     * @notice Deposit a token to TraderJoe for lending / collaterization.
     * @param token Token address
     * @param jToken Respective jToken address
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function deposit(
        address token,
        address jToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        
        (_eventName, _eventParam) = depositRaw(token, jToken, amt, getId, setId);
        
    }

    /**
     * @dev Withdraw AVAX/ERC20_Token.
     * @notice Withdraw deposited token from TraderJoe
     * @param token The address of the token to withdraw. (For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param jToken The address of the corresponding jToken.
     * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdrawRaw(
        address token,
        address jToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        
        uint _amt = getUint(getId, amt);
        
        require(token != address(0) && jToken != address(0), "invalid token/jToken address");

        JTokenInterface jTokenContract = JTokenInterface(jToken);
        
        if (_amt == uint(-1)) {
            TokenInterface tokenContract = TokenInterface(token);
            uint initialBal = token == avaxAddr ? address(this).balance : tokenContract.balanceOf(address(this));
            if(token == avaxAddr){
                require(jTokenContract.redeemNative(jTokenContract.balanceOf(address(this))) == 0, "full-withdraw-failed");
            }
            else{
                require(jTokenContract.redeem(jTokenContract.balanceOf(address(this))) == 0, "full-withdraw-failed");
            }
            
        
            uint finalBal = token == avaxAddr ? address(this).balance : tokenContract.balanceOf(address(this));
           
            _amt = finalBal - initialBal;
            
        } else {
            if(token == avaxAddr){
                require(jTokenContract.redeemUnderlyingNative(_amt) == 0, "withdraw-failed");
            }
            else{
                require(jTokenContract.redeemUnderlying(_amt) == 0, "withdraw-failed");
            }
            
           
        }
        
        setUint(setId, _amt);

        _eventName = "LogWithdraw(address,address,uint256,uint256,uint256)";
        
        _eventParam = abi.encode(token, jToken, _amt, getId, setId);
        
    }

    /**
     * @dev Withdraw AVAX/ERC20_Token using token and jToken addresses.
     * @notice Withdraw deposited token from TraderJoe
     * @param token Token address
     * @param jToken Respective jToken address
     * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdraw(
        address token, 
        address jToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        
        (_eventName, _eventParam) = withdrawRaw(token, jToken, amt, getId, setId);
    }

    /**
     * @dev Borrow AVAX/ERC20_Token.
     * @notice Borrow a token using TraderJoe
     * @param token The address of the token to borrow. (For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param jToken The address of the corresponding jToken.
     * @param amt The amount of the token to borrow.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens borrowed.
    */
    function borrowRaw(
        address token,
        address jToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(token != address(0) && jToken != address(0), "invalid token/jToken address");

        enterMarket(jToken);
        require(JTokenInterface(jToken).borrow(_amt) == 0, "borrow-failed");
        setUint(setId, _amt);

        _eventName = "LogBorrow(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, jToken, _amt, getId, setId);
    }

     /**
     * @dev Borrow AVAX/ERC20_Token token and jToken addresses.
     * @notice Borrow a token using TraderJoe
     * @param token Token address
     * @param jToken Respective jToken address
     * @param amt The amount of the token to borrow.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens borrowed.
    */
    function borrow(
        address token, 
        address jToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (_eventName, _eventParam) = borrowRaw(token, jToken, amt, getId, setId);
    }

    /**
     * @dev Payback borrowed AVAX/ERC20_Token.
     * @notice Payback debt owed.
     * @param token The address of the token to payback. (For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param jToken The address of the corresponding jToken.
     * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens paid back.
    */
    function paybackRaw(
        address token,
        address jToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(token != address(0) && jToken != address(0), "invalid token/jToken address");

        JTokenInterface jTokenContract = JTokenInterface(jToken);
        _amt = _amt == uint(-1) ? jTokenContract.borrowBalanceCurrent(address(this)) : _amt;

        if (token == avaxAddr) {
            require(address(this).balance >= _amt, "not-enough-eth");
            JAVAXInterface(jToken).repayBorrow{value: _amt}();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            approve(tokenContract, jToken, _amt);
            require(jTokenContract.repayBorrow(_amt) == 0, "repay-failed.");
        }
        setUint(setId, _amt);

        _eventName = "LogPayback(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, jToken, _amt, getId, setId);
    }

    /**
     * @dev Payback borrowed AVAX/ERC20_Token using token and jToken addresses.
     * @notice Payback debt owed.
     * @param token Token address
     * @param jToken Respective jToken address
     * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens paid back.
    */
    function payback(
        address token, 
        address jToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        
        (_eventName, _eventParam) = paybackRaw(token, jToken, amt, getId, setId);
    }

    /**
     * @dev Deposit AVAX/ERC20_Token.
     * @notice Same as depositRaw. The only difference is this method stores jToken amount in set ID.
     * @param token The address of the token to deposit. (For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param jToken The address of the corresponding jToken.
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of jTokens received.
    */
    function depositJTokenRaw(
        address token,
        address jToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(token != address(0) && jToken != address(0), "invalid token/jToken address");

        enterMarket(jToken);

        JTokenInterface jTokenContract = JTokenInterface(jToken);
        uint initialBal = jTokenContract.balanceOf(address(this));

        if (token == avaxAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            JAVAXInterface(jToken).mintNative{value: _amt}();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            approve(tokenContract, jToken, _amt);
            require(jTokenContract.mint(_amt) == 0, "deposit-jToken-failed.");
        }

        uint _cAmt;

        {
            uint finalBal = jTokenContract.balanceOf(address(this));
            _cAmt = sub(finalBal, initialBal);

            setUint(setId, _cAmt);
        }

        _eventName = "LogDepositJToken(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, jToken, _amt, _cAmt, getId, setId);
    }

    /**
     * @dev Deposit AVAX/ERC20_Token using token and jToken addresses.
     * @notice Same as deposit. The only difference is this method stores jToken amount in set ID.
     * @param token Token address
     * @param jToken Respective jToken address
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of jTokens received.
    */
    function depositJToken(
        address token, 
        address jToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        
        (_eventName, _eventParam) = depositJTokenRaw(token, jToken, amt, getId, setId);
    }

    /**
     * @dev Withdraw JAVAX/CERC20_Token using jToken Amt.
     * @notice Same as withdrawRaw. The only difference is this method fetch jToken amount in get ID.
     * @param token The address of the token to withdraw. (For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param jToken The address of the corresponding jToken.
     * @param jTokenAmt The amount of jTokens to withdraw
     * @param getId ID to retrieve jTokenAmt 
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdrawJTokenRaw(
        address token,
        address jToken,
        uint jTokenAmt,
        uint getId,
        uint setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _cAmt = getUint(getId, jTokenAmt);
        require(token != address(0) && jToken != address(0), "invalid token/jToken address");

        JTokenInterface jTokenContract = JTokenInterface(jToken);
        TokenInterface tokenContract = TokenInterface(token);
        _cAmt = _cAmt == uint(-1) ? jTokenContract.balanceOf(address(this)) : _cAmt;

        uint withdrawAmt;
        {
            uint initialBal = token != avaxAddr ? tokenContract.balanceOf(address(this)) : address(this).balance;
            if(token == avaxAddr){
                require(jTokenContract.redeemNative(_cAmt) == 0, "redeem-failed");
            }
            else{
                require(jTokenContract.redeem(_cAmt) == 0, "redeem-failed");
            }
            uint finalBal = token != avaxAddr ? tokenContract.balanceOf(address(this)) : address(this).balance;

            withdrawAmt = sub(finalBal, initialBal);
        }

        setUint(setId, withdrawAmt);

        _eventName = "LogWithdrawJToken(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, jToken, withdrawAmt, _cAmt, getId, setId);
    }

    /**
     * @dev Withdraw JAVAX/CERC20_Token using jToken Amt & using token and jToken addresses.
     * @notice Same as withdraw. The only difference is this method fetch jToken amount in get ID.
     * @param token Token address
     * @param jToken Respective jToken address
     * @param jTokenAmt The amount of jTokens to withdraw
     * @param getId ID to retrieve jTokenAmt 
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdrawJToken(
        address token, 
        address jToken,
        uint jTokenAmt,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        
        (_eventName, _eventParam) = withdrawJTokenRaw(token, jToken, jTokenAmt, getId, setId);
    }

    /**
     * @dev Liquidate a position.
     * @notice Liquidate a position.
     * @param borrower Borrower's Address.
     * @param tokenToPay The address of the token to pay for liquidation.(For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param jTokenPay Corresponding jToken address.
     * @param tokenInReturn The address of the token to return for liquidation.
     * @param jTokenColl Corresponding jToken address.
     * @param amt The token amount to pay for liquidation.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of paid for liquidation.
    */
    function liquidateRaw(
        address borrower,
        address tokenToPay,
        address jTokenPay,
        address tokenInReturn,
        address jTokenColl,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        require(tokenToPay != address(0) && jTokenPay != address(0), "invalid token/jToken address");
        require(tokenInReturn != address(0) && jTokenColl != address(0), "invalid token/jToken address");

        JTokenInterface jTokenContract = JTokenInterface(jTokenPay);

        {
            (,, uint shortfal) = troller.getAccountLiquidity(borrower);
            require(shortfal != 0, "account-cannot-be-liquidated");
            _amt = _amt == uint(-1) ? jTokenContract.borrowBalanceCurrent(borrower) : _amt;
        }

        if (tokenToPay == avaxAddr) {
            require(address(this).balance >= _amt, "not-enought-eth");
            JAVAXInterface(jTokenPay).liquidateBorrow{value: _amt}(borrower, jTokenColl);
        } else {
            TokenInterface tokenContract = TokenInterface(tokenToPay);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            approve(tokenContract, jTokenPay, _amt);
            require(jTokenContract.liquidateBorrow(borrower, _amt, jTokenColl) == 0, "liquidate-failed");
        }
        
        setUint(setId, _amt);

        _eventName = "LogLiquidate(address,address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            address(this),
            tokenToPay,
            tokenInReturn, 
            _amt,
            getId,
            setId
        );
    }

    /**
     * @dev Liquidate a position using the tokenToPay, jTokenToPay, tokenInReturn, jTokenColl addresses.
     * @notice Liquidate a position using the tokenToPay, jTokenToPay, tokenInReturn, jTokenColl addresses.
     * @param borrower Borrower's Address.
     * @param tokenToPay Token to pay.
     * @param jTokenToPay Corresponding jToken to pay.
     * @param tokenInReturn Token which you get in return.
     * @param jTokenColl Corresponding jToken which you get in return.
     * @param amt token amount to pay for liquidation.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of paid for liquidation.
    */
    function liquidate(
        address borrower,
        address tokenToPay, 
        address jTokenToPay,
        address tokenInReturn, 
        address jTokenColl,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        

        (_eventName, _eventParam) = liquidateRaw(
            borrower,
            tokenToPay,
            jTokenToPay,
            tokenInReturn,
            jTokenColl,
            amt,
            getId,
            setId
        );
    }
}

contract ConnectV2TraderJoe is TraderJoeResolver {
    string public name = "TraderJoe-v1.1";
}
