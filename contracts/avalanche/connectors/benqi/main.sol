pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Benqi.
 * @dev Lending & Borrowing.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { QiAVAXInterface, QiTokenInterface } from "./interface.sol";

abstract contract BenqiResolver is Events, Helpers {
    /**
     * @dev Deposit AVAX/ARC20_Token.
     * @notice Deposit a token to Benqi for lending / collaterization.
     * @param token The address of the token to deposit. (For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param qiToken The address of the corresponding qiToken.
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function depositRaw(
        address token,
        address qiToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(token != address(0) && qiToken != address(0), "invalid token/qitoken address");

        enterMarket(qiToken);
        if (token == avaxAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            QiAVAXInterface(qiToken).mint{value: _amt}();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            approve(tokenContract, qiToken, _amt);
            require(QiTokenInterface(qiToken).mint(_amt) == 0, "deposit-failed");
        }
        setUint(setId, _amt);

        _eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, qiToken, _amt, getId, setId);
    }

    /**
     * @dev Deposit AVAX/ARC20_Token using the Mapping.
     * @notice Deposit a token to Benqi for lending / collaterization.
     * @param tokenId The token id of the token to deposit.(For eg: AVAX-A)
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
    */
    function deposit(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address token, address qiToken) = qiMapping.getMapping(tokenId);
        (_eventName, _eventParam) = depositRaw(token, qiToken, amt, getId, setId);
    }

    /**
     * @dev Withdraw AVAX/ARC20_Token.
     * @notice Withdraw deposited token from Benqi
     * @param token The address of the token to withdraw. (For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param qiToken The address of the corresponding qiToken.
     * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdrawRaw(
        address token,
        address qiToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        
        require(token != address(0) && qiToken != address(0), "invalid token/qitoken address");

        QiTokenInterface qiTokenContract = QiTokenInterface(qiToken);
        if (_amt == uint(-1)) {
            TokenInterface tokenContract = TokenInterface(token);
            uint initialBal = token == avaxAddr ? address(this).balance : tokenContract.balanceOf(address(this));
            require(qiTokenContract.redeem(qiTokenContract.balanceOf(address(this))) == 0, "full-withdraw-failed");
            uint finalBal = token == avaxAddr ? address(this).balance : tokenContract.balanceOf(address(this));
            _amt = finalBal - initialBal;
        } else {
            require(qiTokenContract.redeemUnderlying(_amt) == 0, "withdraw-failed");
        }
        setUint(setId, _amt);

        _eventName = "LogWithdraw(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, qiToken, _amt, getId, setId);
    }

    /**
     * @dev Withdraw AVAX/ARC20_Token using the Mapping.
     * @notice Withdraw deposited token from Benqi
     * @param tokenId The token id of the token to withdraw.(For eg: AVAX-A)
     * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdraw(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address token, address qiToken) = qiMapping.getMapping(tokenId);
        (_eventName, _eventParam) = withdrawRaw(token, qiToken, amt, getId, setId);
    }

    /**
     * @dev Borrow AVAX/ARC20_Token.
     * @notice Borrow a token using Benqi
     * @param token The address of the token to borrow. (For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param qiToken The address of the corresponding qiToken.
     * @param amt The amount of the token to borrow.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens borrowed.
    */
    function borrowRaw(
        address token,
        address qiToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(token != address(0) && qiToken != address(0), "invalid token/qitoken address");

        enterMarket(qiToken);
        require(QiTokenInterface(qiToken).borrow(_amt) == 0, "borrow-failed");
        setUint(setId, _amt);

        _eventName = "LogBorrow(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, qiToken, _amt, getId, setId);
    }

     /**
     * @dev Borrow AVAX/ARC20_Token using the Mapping.
     * @notice Borrow a token using Benqi
     * @param tokenId The token id of the token to borrow.(For eg: DAI-A)
     * @param amt The amount of the token to borrow.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens borrowed.
    */
    function borrow(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address token, address qiToken) = qiMapping.getMapping(tokenId);
        (_eventName, _eventParam) = borrowRaw(token, qiToken, amt, getId, setId);
    }

    /**
     * @dev Payback borrowed AVAX/ARC20_Token.
     * @notice Payback debt owed.
     * @param token The address of the token to payback. (For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param qiToken The address of the corresponding qiToken.
     * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens paid back.
    */
    function paybackRaw(
        address token,
        address qiToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(token != address(0) && qiToken != address(0), "invalid token/qitoken address");

        QiTokenInterface qiTokenContract = QiTokenInterface(qiToken);
        _amt = _amt == uint(-1) ? qiTokenContract.borrowBalanceCurrent(address(this)) : _amt;

        if (token == avaxAddr) {
            require(address(this).balance >= _amt, "not-enough-avax");
            QiAVAXInterface(qiToken).repayBorrow{value: _amt}();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            approve(tokenContract, qiToken, _amt);
            require(qiTokenContract.repayBorrow(_amt) == 0, "repay-failed.");
        }
        setUint(setId, _amt);

        _eventName = "LogPayback(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, qiToken, _amt, getId, setId);
    }

    /**
     * @dev Payback borrowed AVAX/ARC20_Token using the Mapping.
     * @notice Payback debt owed.
     * @param tokenId The token id of the token to payback.(For eg: BENQI-A)
     * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens paid back.
    */
    function payback(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address token, address qiToken) = qiMapping.getMapping(tokenId);
        (_eventName, _eventParam) = paybackRaw(token, qiToken, amt, getId, setId);
    }

    /**
     * @dev Deposit AVAX/ARC20_Token.
     * @notice Same as depositRaw. The only difference is this method stores qiToken amount in set ID.
     * @param token The address of the token to deposit. (For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param qiToken The address of the corresponding qiToken.
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of qiTokens received.
    */
    function depositQiTokenRaw(
        address token,
        address qiToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(token != address(0) && qiToken != address(0), "invalid token/qitoken address");

        enterMarket(qiToken);

        QiTokenInterface qitokenContract = QiTokenInterface(qiToken);
        uint initialBal = qitokenContract.balanceOf(address(this));

        if (token == avaxAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            QiAVAXInterface(qiToken).mint{value: _amt}();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            approve(tokenContract, qiToken, _amt);
            require(qitokenContract.mint(_amt) == 0, "deposit-qitoken-failed.");
        }

        uint _cAmt;

        {
            uint finalBal = qitokenContract.balanceOf(address(this));
            _cAmt = sub(finalBal, initialBal);

            setUint(setId, _cAmt);
        }

        _eventName = "LogDepositQiToken(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, qiToken, _amt, _cAmt, getId, setId);
    }

    /**
     * @dev Deposit AVAX/ARC20_Token using the Mapping.
     * @notice Same as deposit. The only difference is this method stores qiToken amount in set ID.
     * @param tokenId The token id of the token to depositQiToken.(For eg: DAI-A)
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of qiTokens received.
    */
    function depositQiToken(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address token, address qiToken) = qiMapping.getMapping(tokenId);
        (_eventName, _eventParam) = depositQiTokenRaw(token, qiToken, amt, getId, setId);
    }

    /**
     * @dev Withdraw QiAVAX/QiARC20_Token using qiToken Amt.
     * @notice Same as withdrawRaw. The only difference is this method fetch qiToken amount in get ID.
     * @param token The address of the token to withdraw. (For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param qiToken The address of the corresponding qiToken.
     * @param qiTokenAmt The amount of qiTokens to withdraw
     * @param getId ID to retrieve qiTokenAmt 
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdrawQiTokenRaw(
        address token,
        address qiToken,
        uint qiTokenAmt,
        uint getId,
        uint setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _cAmt = getUint(getId, qiTokenAmt);
        require(token != address(0) && qiToken != address(0), "invalid token/qitoken address");

        QiTokenInterface qiTokenContract = QiTokenInterface(qiToken);
        TokenInterface tokenContract = TokenInterface(token);
        _cAmt = _cAmt == uint(-1) ? qiTokenContract.balanceOf(address(this)) : _cAmt;

        uint withdrawAmt;
        {
            uint initialBal = token != avaxAddr ? tokenContract.balanceOf(address(this)) : address(this).balance;
            require(qiTokenContract.redeem(_cAmt) == 0, "redeem-failed");
            uint finalBal = token != avaxAddr ? tokenContract.balanceOf(address(this)) : address(this).balance;

            withdrawAmt = sub(finalBal, initialBal);
        }

        setUint(setId, withdrawAmt);

        _eventName = "LogWithdrawQiToken(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, qiToken, withdrawAmt, _cAmt, getId, setId);
    }

    /**
     * @dev Withdraw QiAVAX/QiARC20_Token using qiToken Amt & the Mapping.
     * @notice Same as withdraw. The only difference is this method fetch qiToken amount in get ID.
     * @param tokenId The token id of the token to withdraw QiToken.(For eg: AVAX-A)
     * @param qiTokenAmt The amount of qiTokens to withdraw
     * @param getId ID to retrieve qiTokenAmt 
     * @param setId ID stores the amount of tokens withdrawn.
    */
    function withdrawQiToken(
        string calldata tokenId,
        uint qiTokenAmt,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address token, address qiToken) = qiMapping.getMapping(tokenId);
        (_eventName, _eventParam) = withdrawQiTokenRaw(token, qiToken, qiTokenAmt, getId, setId);
    }

    /**
     * @dev Liquidate a position.
     * @notice Liquidate a position.
     * @param borrower Borrower's Address.
     * @param tokenToPay The address of the token to pay for liquidation.(For AVAX: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param qiTokenPay Corresponding qiToken address.
     * @param tokenInReturn The address of the token to return for liquidation.
     * @param qiTokenColl Corresponding qiToken address.
     * @param amt The token amount to pay for liquidation.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of paid for liquidation.
    */
    function liquidateRaw(
        address borrower,
        address tokenToPay,
        address qiTokenPay,
        address tokenInReturn,
        address qiTokenColl,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        require(tokenToPay != address(0) && qiTokenPay != address(0), "invalid token/qitoken address");
        require(tokenInReturn != address(0) && qiTokenColl != address(0), "invalid token/qitoken address");

        QiTokenInterface qiTokenContract = QiTokenInterface(qiTokenPay);

        {
            (,, uint shortfal) = troller.getAccountLiquidity(borrower);
            require(shortfal != 0, "account-cannot-be-liquidated");
            _amt = _amt == uint(-1) ? qiTokenContract.borrowBalanceCurrent(borrower) : _amt;
        }

        if (tokenToPay == avaxAddr) {
            require(address(this).balance >= _amt, "not-enough-avax");
            QiAVAXInterface(qiTokenPay).liquidateBorrow{value: _amt}(borrower, qiTokenColl);
        } else {
            TokenInterface tokenContract = TokenInterface(tokenToPay);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            approve(tokenContract, qiTokenPay, _amt);
            require(qiTokenContract.liquidateBorrow(borrower, _amt, qiTokenColl) == 0, "liquidate-failed");
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
     * @dev Liquidate a position using the mapping.
     * @notice Liquidate a position using the mapping.
     * @param borrower Borrower's Address.
     * @param tokenIdToPay token id of the token to pay for liquidation.(For eg: AVAX-A)
     * @param tokenIdInReturn token id of the token to return for liquidation.(For eg: USDC-A)
     * @param amt token amount to pay for liquidation.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of paid for liquidation.
    */
    function liquidate(
        address borrower,
        string calldata tokenIdToPay,
        string calldata tokenIdInReturn,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (address tokenToPay, address qiTokenToPay) = qiMapping.getMapping(tokenIdToPay);
        (address tokenInReturn, address qiTokenColl) = qiMapping.getMapping(tokenIdInReturn);

        (_eventName, _eventParam) = liquidateRaw(
            borrower,
            tokenToPay,
            qiTokenToPay,
            tokenInReturn,
            qiTokenColl,
            amt,
            getId,
            setId
        );
    }
}

contract ConnectV2Benqi is BenqiResolver {
    string public name = "Benqi-v1.1";
}
