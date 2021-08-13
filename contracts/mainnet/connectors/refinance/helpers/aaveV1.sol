pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { protocolHelpers } from "../helpers.sol";

import {
    AaveV1ProviderInterface,
    AaveV1Interface,
    AaveV1CoreInterface,
    ATokenV1Interface,
    CTokenInterface
    // AaveV2LendingPoolProviderInterface, 
    // AaveV2DataProviderInterface,
    // AaveV2Interface,
} from "../interfaces.sol";

import { TokenInterface } from "../../../common/interfaces.sol";

contract AaveV1Helpers is protocolHelpers {

    struct AaveV1BorrowData {
        AaveV1Interface aave;
        uint length;
        uint fee;
        Protocol target;
        TokenInterface[] tokens;
        CTokenInterface[] ctokens;
        uint[] amts;
        uint[] borrowRateModes;
        uint[] paybackRateModes;
    }

    struct AaveV1DepositData {
        AaveV1Interface aave;
        AaveV1CoreInterface aaveCore;
        uint length;
        uint fee;
        TokenInterface[] tokens;
        uint[] amts;
    }

    function _aaveV1BorrowOne(
        AaveV1Interface aave,
        uint fee,
        Protocol target,
        TokenInterface token,
        CTokenInterface ctoken,
        uint amt,
        uint borrowRateMode,
        uint paybackRateMode
    ) internal returns (uint) {
        if (amt > 0) {

            address _token = address(token) == wethAddr ? ethAddr : address(token);

            if (amt == uint(-1)) {
                amt = getMaxBorrow(target, address(token), ctoken, paybackRateMode);
            }

            (uint feeAmt, uint _amt) = calculateFee(amt, fee, true);

            aave.borrow(_token, _amt, borrowRateMode, getReferralCode);
            transferFees(_token, feeAmt);
        }
        return amt;
    }

    function _aaveV1Borrow(
        AaveV1BorrowData memory data
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](data.length);
        for (uint i = 0; i < data.length; i++) {
            finalAmts[i] = _aaveV1BorrowOne(
                data.aave,
                data.fee,
                data.target,
                data.tokens[i],
                data.ctokens[i],
                data.amts[i],
                data.borrowRateModes[i],
                data.paybackRateModes[i]
            );
        }
        return finalAmts;
    }

    function _aaveV1DepositOne(
        AaveV1Interface aave,
        AaveV1CoreInterface aaveCore,
        uint fee,
        TokenInterface token,
        uint amt
    ) internal {
        if (amt > 0) {
            uint ethAmt;
            (uint feeAmt, uint _amt) = calculateFee(amt, fee, false);

            bool isEth = address(token) == wethAddr;

            address _token = isEth ? ethAddr : address(token);

            if (isEth) {
                ethAmt = _amt;
            } else {
                approve(token, address(aaveCore), _amt);
            }

            transferFees(_token, feeAmt);

            aave.deposit{value:ethAmt}(_token, _amt, getReferralCode);

            if (!getIsColl(aave, _token))
                aave.setUserUseReserveAsCollateral(_token, true);
        }
    }

    function _aaveV1Deposit(
        AaveV1DepositData memory data
    ) internal {
        for (uint i = 0; i < data.length; i++) {
            _aaveV1DepositOne(
                data.aave,
                data.aaveCore,
                data.fee,
                data.tokens[i],
                data.amts[i]
            );
        }
    }

    function _aaveV1WithdrawOne(
        AaveV1Interface aave,
        AaveV1CoreInterface aaveCore,
        TokenInterface token,
        uint amt
    ) internal returns (uint) {
        if (amt > 0) {
            address _token = address(token) == wethAddr ? ethAddr : address(token);
            ATokenV1Interface atoken = ATokenV1Interface(aaveCore.getReserveATokenAddress(_token));
            if (amt == uint(-1)) {
                amt = getWithdrawBalance(aave, _token);
            }
            atoken.redeem(amt);
        }
        return amt;
    }

    function _aaveV1Withdraw(
        AaveV1Interface aave,
        AaveV1CoreInterface aaveCore,
        uint length,
        TokenInterface[] memory tokens,
        uint[] memory amts
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](length);
        for (uint i = 0; i < length; i++) {
            finalAmts[i] = _aaveV1WithdrawOne(aave, aaveCore, tokens[i], amts[i]);
        }
        return finalAmts;
    }

    function _aaveV1PaybackOne(
        AaveV1Interface aave,
        AaveV1CoreInterface aaveCore,
        TokenInterface token,
        uint amt
    ) internal returns (uint) {
        if (amt > 0) {
            uint ethAmt;

            bool isEth = address(token) == wethAddr;

            address _token = isEth ? ethAddr : address(token);

            if (amt == uint(-1)) {
                (uint _amt, uint _fee) = getPaybackBalance(aave, _token);
                amt = _amt + _fee;
            }

            if (isEth) {
                ethAmt = amt;
            } else {
                approve(token, address(aaveCore), amt);
            }

            aave.repay{value:ethAmt}(_token, amt, payable(address(this)));
        }
        return amt;
    }

    function _aaveV1Payback(
        AaveV1Interface aave,
        AaveV1CoreInterface aaveCore,
        uint length,
        TokenInterface[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            _aaveV1PaybackOne(aave, aaveCore, tokens[i], amts[i]);
        }
    }
}
