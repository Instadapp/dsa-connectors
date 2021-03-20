pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { CETHInterface, CTokenInterface, LiquidateData } from "./interface.sol";

abstract contract CompoundResolver is Events, Helpers {
    /**
     * @dev Deposit ETH/ERC20_Token.
     * @param tokenId token id of the token to deposit.(For eg: ETH-A)
     * @param amt token amount to deposit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        (address token, address cToken) = compMapping.getMapping(tokenId);
        require(token != address(0) && cToken != address(0), "ctoken mapping not found");

        enterMarket(cToken);
        if (token == ethAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            CETHInterface(cToken).mint{value: _amt}();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(cToken, _amt);
            require(CTokenInterface(cToken).mint(_amt) == 0, "deposit-failed");
        }
        setUint(setId, _amt);

        _eventName = "LogDeposit(address,string,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, tokenId, cToken, _amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @param tokenId token id of the token to withdraw.(For eg: ETH-A)
     * @param amt token amount to withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdraw(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        
        (address token, address cToken) = compMapping.getMapping(tokenId);
        require(token != address(0) && cToken != address(0), "ctoken mapping not found");

        CTokenInterface cTokenContract = CTokenInterface(cToken);
        if (_amt == uint(-1)) {
            TokenInterface tokenContract = TokenInterface(token);
            uint initialBal = token == ethAddr ? address(this).balance : tokenContract.balanceOf(address(this));
            require(cTokenContract.redeem(cTokenContract.balanceOf(address(this))) == 0, "full-withdraw-failed");
            uint finalBal = token == ethAddr ? address(this).balance : tokenContract.balanceOf(address(this));
            _amt = finalBal - initialBal;
        } else {
            require(cTokenContract.redeemUnderlying(_amt) == 0, "withdraw-failed");
        }
        setUint(setId, _amt);

        _eventName = "LogWithdraw(address,string,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, tokenId, cToken, _amt, getId, setId);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @param tokenId token id of the token to borrow.(For eg: DAI-A)
     * @param amt token amount to borrow.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function borrow(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        (address token, address cToken) = compMapping.getMapping(tokenId);
        require(token != address(0) && cToken != address(0), "ctoken mapping not found");

        enterMarket(cToken);
        require(CTokenInterface(cToken).borrow(_amt) == 0, "borrow-failed");
        setUint(setId, _amt);

        _eventName = "LogBorrow(address,string,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, tokenId, cToken, _amt, getId, setId);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @param tokenId token id of the token to payback.(For eg: COMP-A)
     * @param amt token amount to payback.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function payback(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        (address token, address cToken) = compMapping.getMapping(tokenId);
        require(token != address(0) && cToken != address(0), "ctoken mapping not found");

        CTokenInterface cTokenContract = CTokenInterface(cToken);
        _amt = _amt == uint(-1) ? cTokenContract.borrowBalanceCurrent(address(this)) : _amt;

        if (token == ethAddr) {
            require(address(this).balance >= _amt, "not-enough-eth");
            CETHInterface(cToken).repayBorrow{value: _amt}();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            tokenContract.approve(cToken, _amt);
            require(cTokenContract.repayBorrow(_amt) == 0, "repay-failed.");
        }
        setUint(setId, _amt);

        _eventName = "LogPayback(address,string,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, tokenId, cToken, _amt, getId, setId);
    }

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @param tokenId token id of the token to depositCToken.(For eg: DAI-A)
     * @param amt token amount to depositCToken.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function depositCToken(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        (address token, address cToken) = compMapping.getMapping(tokenId);
        require(token != address(0) && cToken != address(0), "ctoken mapping not found");

        enterMarket(cToken);

        CTokenInterface ctokenContract = CTokenInterface(cToken);
        uint initialBal = ctokenContract.balanceOf(address(this));

        if (token == ethAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            CETHInterface(cToken).mint{value: _amt}();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(cToken, _amt);
            require(ctokenContract.mint(_amt) == 0, "deposit-ctoken-failed.");
        }

        uint _cAmt;

        {
            uint finalBal = ctokenContract.balanceOf(address(this));
            finalBal - initialBal;
            setUint(setId, _cAmt);
        }

        _eventName = "LogDepositCToken(address,string,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, tokenId, cToken, _amt, _cAmt, getId, setId);
    }

    /**
     * @dev Withdraw CETH/CERC20_Token using cToken Amt.
     * @param tokenId token id of the token to withdraw CToken.(For eg: ETH-A)
     * @param cTokenAmt ctoken amount to withdrawCToken.
     * @param getId Get ctoken amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdrawCToken(
        string calldata tokenId,
        uint cTokenAmt,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _cAmt = getUint(getId, cTokenAmt);
        (address token, address cToken) = compMapping.getMapping(tokenId);
        require(token != address(0) && cToken != address(0), "ctoken mapping not found");

        CTokenInterface cTokenContract = CTokenInterface(cToken);
        TokenInterface tokenContract = TokenInterface(token);
        _cAmt = _cAmt == uint(-1) ? cTokenContract.balanceOf(address(this)) : _cAmt;

        uint withdrawAmt;
        {
            uint initialBal = token != ethAddr ? tokenContract.balanceOf(address(this)) : address(this).balance;
            require(cTokenContract.redeem(_cAmt) == 0, "redeem-failed");
            uint finalBal = token != ethAddr ? tokenContract.balanceOf(address(this)) : address(this).balance;

            withdrawAmt = sub(finalBal, initialBal);
        }

        setUint(setId, withdrawAmt);

        _eventName = "LogWithdrawCToken(address,string,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, tokenId, cToken, withdrawAmt, _cAmt, getId, setId);
    }

    /**
     * @dev Liquidate a position.
     * @param borrower Borrower's Address.
     * @param tokenIdToPay token id of the token to pay for liquidation.(For eg: ETH-A)
     * @param tokenIdInReturn token id of the token to return for liquidation.(For eg: USDC-A)
     * @param amt token amount to pay for liquidation.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function liquidate(
        address borrower,
        string calldata tokenIdToPay,
        string calldata tokenIdInReturn,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        LiquidateData memory data;

        (data.tokenToPay, data.cTokenPay) = compMapping.getMapping(tokenIdToPay);
        (data.tokenInReturn, data.cTokenColl) = compMapping.getMapping(tokenIdInReturn);
        data.cTokenContract = CTokenInterface(data.cTokenPay);

        {
            (,, uint shortfal) = troller.getAccountLiquidity(borrower);
            require(shortfal != 0, "account-cannot-be-liquidated");
            _amt = _amt == uint(-1) ? data.cTokenContract.borrowBalanceCurrent(borrower) : _amt;
        }

        if (data.tokenToPay == ethAddr) {
            require(address(this).balance >= _amt, "not-enought-eth");
            CETHInterface(data.cTokenPay).liquidateBorrow{value: _amt}(borrower, data.cTokenColl);
        } else {
            TokenInterface tokenContract = TokenInterface(data.tokenToPay);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            tokenContract.approve(data.cTokenPay, _amt);
            require(data.cTokenContract.liquidateBorrow(borrower, _amt, data.cTokenColl) == 0, "liquidate-failed");
        }
        
        setUint(setId, _amt);

        _eventName = "LogLiquidate(address,address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            address(this),
            data.tokenToPay,
            data.tokenInReturn, 
            _amt,
            getId,
            setId
        );
    }
}

contract ConnectV2Compound is CompoundResolver {
    string public name = "Compound-v1";
}
