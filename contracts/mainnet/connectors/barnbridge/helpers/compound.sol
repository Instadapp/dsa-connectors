pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { protocolHelpers } from "../helpers.sol";

import {
    ComptrollerInterface,
    CTokenInterface,
    CompoundMappingInterface,
    CETHInterface
} from "../interfaces.sol";

import { TokenInterface } from "../../../common/interfaces.sol";



contract CompoundHelpers is protocolHelpers {

    struct CompoundBorrowData {
        uint length;
        uint fee;
        Protocol target;
        CTokenInterface[] ctokens;
        TokenInterface[] tokens;
        uint[] amts;
        uint[] rateModes;
    }

    function _compEnterMarkets(uint length, CTokenInterface[] memory ctokens) internal {
        ComptrollerInterface troller = ComptrollerInterface(getComptrollerAddress);
        address[] memory _cTokens = new address[](length);

        for (uint i = 0; i < length; i++) {
            _cTokens[i] = address(ctokens[i]);
        }
        troller.enterMarkets(_cTokens);
    }

    function _compBorrowOne(
        uint fee,
        CTokenInterface ctoken,
        TokenInterface token,
        uint amt,
        Protocol target,
        uint rateMode
    ) internal returns (uint) {
        if (amt > 0) {
            address _token = address(token) == wethAddr ? ethAddr : address(token);

            if (amt == uint(-1)) {
                amt = getMaxBorrow(target, address(token), ctoken, rateMode);
            }

            (uint feeAmt, uint _amt) = calculateFee(amt, fee, true);

            require(ctoken.borrow(_amt) == 0, "borrow-failed-collateral?");
            transferFees(_token, feeAmt);
        }
        return amt;
    }

    function _compBorrow(
        CompoundBorrowData memory data
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](data.length);
        for (uint i = 0; i < data.length; i++) {
            finalAmts[i] = _compBorrowOne(
                data.fee, 
                data.ctokens[i], 
                data.tokens[i], 
                data.amts[i], 
                data.target, 
                data.rateModes[i]
            );
        }
        return finalAmts;
    }

    function _compDepositOne(uint fee, CTokenInterface ctoken, TokenInterface token, uint amt) internal {
        if (amt > 0) {
            address _token = address(token) == wethAddr ? ethAddr : address(token);

            (uint feeAmt, uint _amt) = calculateFee(amt, fee, false);

            if (_token != ethAddr) {
                approve(token, address(ctoken), _amt);
                require(ctoken.mint(_amt) == 0, "deposit-failed");
            } else {
                CETHInterface(address(ctoken)).mint{value:_amt}();
            }
            transferFees(_token, feeAmt);
        }
    }

    function _compDeposit(
        uint length,
        uint fee,
        CTokenInterface[] memory ctokens,
        TokenInterface[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            _compDepositOne(fee, ctokens[i], tokens[i], amts[i]);
        }
    }

    function _compWithdrawOne(CTokenInterface ctoken, TokenInterface token, uint amt) internal returns (uint) {
        if (amt > 0) {
            if (amt == uint(-1)) {
                bool isEth = address(token) == wethAddr;
                uint initalBal = isEth ? address(this).balance : token.balanceOf(address(this));
                require(ctoken.redeem(ctoken.balanceOf(address(this))) == 0, "withdraw-failed");
                uint finalBal = isEth ? address(this).balance : token.balanceOf(address(this));
                amt = sub(finalBal, initalBal);
            } else {
                require(ctoken.redeemUnderlying(amt) == 0, "withdraw-failed");
            }
        }
        return amt;
    }

    function _compWithdraw(
        uint length,
        CTokenInterface[] memory ctokens,
        TokenInterface[] memory tokens,
        uint[] memory amts
    ) internal returns(uint[] memory) {
        uint[] memory finalAmts = new uint[](length);
        for (uint i = 0; i < length; i++) {
            finalAmts[i] = _compWithdrawOne(ctokens[i], tokens[i], amts[i]);
        }
        return finalAmts;
    }

    function _compPaybackOne(CTokenInterface ctoken, TokenInterface token, uint amt) internal returns (uint) {
        if (amt > 0) {
            if (amt == uint(-1)) {
                amt = ctoken.borrowBalanceCurrent(address(this));
            }
            if (address(token) != wethAddr) {
                approve(token, address(ctoken), amt);
                require(ctoken.repayBorrow(amt) == 0, "repay-failed.");
            } else {
                CETHInterface(address(ctoken)).repayBorrow{value:amt}();
            }
        }
        return amt;
    }

    function _compPayback(
        uint length,
        CTokenInterface[] memory ctokens,
        TokenInterface[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            _compPaybackOne(ctokens[i], tokens[i], amts[i]);
        }
    }
}