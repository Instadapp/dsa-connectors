pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { protocolHelpers } from "../helpers.sol";

import {
    // AaveV1ProviderInterface,
    // AaveV1Interface,
    // AaveV1CoreInterface,
    AaveV2LendingPoolProviderInterface, 
    AaveV2DataProviderInterface,
    AaveV2Interface,
    ATokenV1Interface,
    CTokenInterface
} from "../interfaces.sol";

import { TokenInterface } from "../../../common/interfaces.sol";

contract AaveV2Helpers is protocolHelpers {

    struct AaveV2BorrowData {
        AaveV2Interface aave;
        uint length;
        uint fee;
        Protocol target;
        TokenInterface[] tokens;
        CTokenInterface[] ctokens;
        uint[] amts;
        uint[] rateModes;
    }

    struct AaveV2PaybackData {
        AaveV2Interface aave;
        AaveV2DataProviderInterface aaveData;
        uint length;
        TokenInterface[] tokens;
        uint[] amts;
        uint[] rateModes;
    }

    struct AaveV2WithdrawData {
        AaveV2Interface aave;
        AaveV2DataProviderInterface aaveData;
        uint length;
        TokenInterface[] tokens;
        uint[] amts;
    }

    function _aaveV2BorrowOne(
        AaveV2Interface aave,
        uint fee,
        Protocol target,
        TokenInterface token,
        CTokenInterface ctoken,
        uint amt,
        uint rateMode
    ) internal returns (uint) {
        if (amt > 0) {
            bool isEth = address(token) == wethAddr;
            
            address _token = isEth ? ethAddr : address(token);

            if (amt == uint(-1)) {
                amt = getMaxBorrow(target, _token, ctoken, rateMode);
            }

            (uint feeAmt, uint _amt) = calculateFee(amt, fee, true);

            aave.borrow(address(token), _amt, rateMode, getReferralCode, address(this));
            convertWethToEth(isEth, token, amt);

            transferFees(_token, feeAmt);
        }
        return amt;
    }

    function _aaveV2Borrow(
        AaveV2BorrowData memory data
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](data.length);
        for (uint i = 0; i < data.length; i++) {
            finalAmts[i] = _aaveV2BorrowOne(
                data.aave,
                data.fee,
                data.target,
                data.tokens[i],
                data.ctokens[i],
                data.amts[i],
                data.rateModes[i]
            );
        }
        return finalAmts;
    }

    function _aaveV2DepositOne(
        AaveV2Interface aave,
        AaveV2DataProviderInterface aaveData,
        uint fee,
        TokenInterface token,
        uint amt
    ) internal {
        if (amt > 0) {
            (uint feeAmt, uint _amt) = calculateFee(amt, fee, false);

            bool isEth = address(token) == wethAddr;
            address _token = isEth ? ethAddr : address(token);

            transferFees(_token, feeAmt);

            convertEthToWeth(isEth, token, _amt);

            approve(token, address(aave), _amt);

            aave.deposit(address(token), _amt, address(this), getReferralCode);

            if (!getIsCollV2(aaveData, address(token))) {
                aave.setUserUseReserveAsCollateral(address(token), true);
            }
        }
    }

    function _aaveV2Deposit(
        AaveV2Interface aave,
        AaveV2DataProviderInterface aaveData,
        uint length,
        uint fee,
        TokenInterface[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            _aaveV2DepositOne(aave, aaveData, fee, tokens[i], amts[i]);
        }
    }

    function _aaveV2WithdrawOne(
        AaveV2Interface aave,
        AaveV2DataProviderInterface aaveData,
        TokenInterface token,
        uint amt
    ) internal returns (uint _amt) {
        if (amt > 0) {
            bool isEth = address(token) == wethAddr;

            aave.withdraw(address(token), amt, address(this));

            _amt = amt == uint(-1) ? getWithdrawBalanceV2(aaveData, address(token)) : amt;

            convertWethToEth(isEth, token, _amt);
        }
    }

    function _aaveV2Withdraw(
        AaveV2WithdrawData memory data
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](data.length);
        for (uint i = 0; i < data.length; i++) {
            finalAmts[i] = _aaveV2WithdrawOne(
                data.aave,
                data.aaveData,
                data.tokens[i],
                data.amts[i]
            );
        }
        return finalAmts;
    }

    function _aaveV2PaybackOne(
        AaveV2Interface aave,
        AaveV2DataProviderInterface aaveData,
        TokenInterface token,
        uint amt,
        uint rateMode
    ) internal returns (uint _amt) {
        if (amt > 0) {
            bool isEth = address(token) == wethAddr;

            _amt = amt == uint(-1) ? getPaybackBalanceV2(aaveData, address(token), rateMode) : amt;

            convertEthToWeth(isEth, token, _amt);

            approve(token, address(aave), _amt);

            aave.repay(address(token), _amt, rateMode, address(this));
        }
    }

    function _aaveV2Payback(
        AaveV2PaybackData memory data
    ) internal {
        for (uint i = 0; i < data.length; i++) {
            _aaveV2PaybackOne(
                data.aave,
                data.aaveData,
                data.tokens[i],
                data.amts[i],
                data.rateModes[i]
            );
        }
    }
}
