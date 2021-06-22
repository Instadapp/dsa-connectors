pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Refinance.
 * @dev Refinancing.
 */

import { TokenInterface } from "../../common/interfaces.sol";

import {
    AaveV1ProviderInterface,
    AaveV1Interface,
    AaveV1CoreInterface,
    AaveV2LendingPoolProviderInterface, 
    AaveV2DataProviderInterface,
    AaveV2Interface,
    ComptrollerInterface,
    CTokenInterface,
    CompoundMappingInterface
} from "./interfaces.sol";


import { AaveV1Helpers } from "./helpers/aaveV1.sol";
import { AaveV2Helpers } from "./helpers/aaveV2.sol";
import { CompoundHelpers } from "./helpers/compound.sol";


contract RefinanceResolver is CompoundHelpers, AaveV1Helpers, AaveV2Helpers {

    struct RefinanceData {
        Protocol source;
        Protocol target;
        uint collateralFee;
        uint debtFee;
        address[] tokens;
        string[] ctokenIds;
        uint[] borrowAmts;
        uint[] withdrawAmts;
        uint[] borrowRateModes;
        uint[] paybackRateModes;
    }

    /**
     * @dev Refinance
     * @notice Refinancing between AaveV1, AaveV2 and Compound
     * @param data refinance data.
    */
    function refinance(RefinanceData calldata data) external payable {

        require(data.source != data.target, "source-and-target-unequal");

        uint length = data.tokens.length;

        require(data.borrowAmts.length == length, "length-mismatch");
        require(data.withdrawAmts.length == length, "length-mismatch");
        require(data.borrowRateModes.length == length, "length-mismatch");
        require(data.paybackRateModes.length == length, "length-mismatch");
        require(data.ctokenIds.length == length, "length-mismatch");

        AaveV2Interface aaveV2 = AaveV2Interface(getAaveV2Provider.getLendingPool());
        AaveV1Interface aaveV1 = AaveV1Interface(getAaveProvider.getLendingPool());
        AaveV1CoreInterface aaveCore = AaveV1CoreInterface(getAaveProvider.getLendingPoolCore());
        AaveV2DataProviderInterface aaveData = getAaveV2DataProvider;

        uint[] memory depositAmts;
        uint[] memory paybackAmts;

        TokenInterface[] memory tokens = getTokenInterfaces(length, data.tokens);
        CTokenInterface[] memory _ctokens = getCtokenInterfaces(length, data.ctokenIds);

        if (data.source == Protocol.Aave && data.target == Protocol.AaveV2) {
            AaveV2BorrowData memory _aaveV2BorrowData;

            _aaveV2BorrowData.aave = aaveV2;
            _aaveV2BorrowData.length = length;
            _aaveV2BorrowData.fee = data.debtFee;
            _aaveV2BorrowData.target = data.source;
            _aaveV2BorrowData.tokens = tokens;
            _aaveV2BorrowData.ctokens = _ctokens;
            _aaveV2BorrowData.amts = data.borrowAmts;
            _aaveV2BorrowData.rateModes = data.borrowRateModes;

            paybackAmts = _aaveV2Borrow(_aaveV2BorrowData);
            _aaveV1Payback(aaveV1, aaveCore, length, tokens, paybackAmts);
            depositAmts = _aaveV1Withdraw(aaveV1, aaveCore, length, tokens, data.withdrawAmts);
            _aaveV2Deposit(aaveV2, aaveData, length, data.collateralFee, tokens, depositAmts);
        } else if (data.source == Protocol.Aave && data.target == Protocol.Compound) {
            _compEnterMarkets(length, _ctokens);

            CompoundBorrowData memory _compoundBorrowData;

            _compoundBorrowData.length = length;
            _compoundBorrowData.fee = data.debtFee;
            _compoundBorrowData.target = data.source;
            _compoundBorrowData.ctokens = _ctokens;
            _compoundBorrowData.tokens = tokens;
            _compoundBorrowData.amts = data.borrowAmts;
            _compoundBorrowData.rateModes = data.borrowRateModes;

            paybackAmts = _compBorrow(_compoundBorrowData);
            
            _aaveV1Payback(aaveV1, aaveCore, length, tokens, paybackAmts);
            depositAmts = _aaveV1Withdraw(aaveV1, aaveCore, length, tokens, data.withdrawAmts);
            _compDeposit(length, data.collateralFee, _ctokens, tokens, depositAmts);
        } else if (data.source == Protocol.AaveV2 && data.target == Protocol.Aave) {

            AaveV1BorrowData memory _aaveV1BorrowData;
            AaveV2PaybackData memory _aaveV2PaybackData;
            AaveV2WithdrawData memory _aaveV2WithdrawData;

            {
                _aaveV1BorrowData.aave = aaveV1;
                _aaveV1BorrowData.length = length;
                _aaveV1BorrowData.fee = data.debtFee;
                _aaveV1BorrowData.target = data.source;
                _aaveV1BorrowData.tokens = tokens;
                _aaveV1BorrowData.ctokens = _ctokens;
                _aaveV1BorrowData.amts = data.borrowAmts;
                _aaveV1BorrowData.borrowRateModes = data.borrowRateModes;
                _aaveV1BorrowData.paybackRateModes = data.paybackRateModes;

                paybackAmts = _aaveV1Borrow(_aaveV1BorrowData);
            }
            
            {
                _aaveV2PaybackData.aave = aaveV2;
                _aaveV2PaybackData.aaveData = aaveData;
                _aaveV2PaybackData.length = length;
                _aaveV2PaybackData.tokens = tokens;
                _aaveV2PaybackData.amts = paybackAmts;
                _aaveV2PaybackData.rateModes = data.paybackRateModes;
                _aaveV2Payback(_aaveV2PaybackData);
            }

            {
                _aaveV2WithdrawData.aave = aaveV2;
                _aaveV2WithdrawData.aaveData = aaveData;
                _aaveV2WithdrawData.length = length;
                _aaveV2WithdrawData.tokens = tokens;
                _aaveV2WithdrawData.amts = data.withdrawAmts;
                depositAmts = _aaveV2Withdraw(_aaveV2WithdrawData);
            }
            {
                AaveV1DepositData memory _aaveV1DepositData;
                
                _aaveV1DepositData.aave = aaveV1;
                _aaveV1DepositData.aaveCore = aaveCore;
                _aaveV1DepositData.length = length;
                _aaveV1DepositData.fee = data.collateralFee;
                _aaveV1DepositData.tokens = tokens;
                _aaveV1DepositData.amts = depositAmts;

                _aaveV1Deposit(_aaveV1DepositData);
            }
        } else if (data.source == Protocol.AaveV2 && data.target == Protocol.Compound) {
            _compEnterMarkets(length, _ctokens);

            {
                CompoundBorrowData memory _compoundBorrowData;

                _compoundBorrowData.length = length;
                _compoundBorrowData.fee = data.debtFee;
                _compoundBorrowData.target = data.source;
                _compoundBorrowData.ctokens = _ctokens;
                _compoundBorrowData.tokens = tokens;
                _compoundBorrowData.amts = data.borrowAmts;
                _compoundBorrowData.rateModes = data.borrowRateModes;

                paybackAmts = _compBorrow(_compoundBorrowData);
            }

            AaveV2PaybackData memory _aaveV2PaybackData;

            _aaveV2PaybackData.aave = aaveV2;
            _aaveV2PaybackData.aaveData = aaveData;
            _aaveV2PaybackData.length = length;
            _aaveV2PaybackData.tokens = tokens;
            _aaveV2PaybackData.amts = paybackAmts;
            _aaveV2PaybackData.rateModes = data.paybackRateModes;
            
            _aaveV2Payback(_aaveV2PaybackData);

            {
                AaveV2WithdrawData memory _aaveV2WithdrawData;

                _aaveV2WithdrawData.aave = aaveV2;
                _aaveV2WithdrawData.aaveData = aaveData;
                _aaveV2WithdrawData.length = length;
                _aaveV2WithdrawData.tokens = tokens;
                _aaveV2WithdrawData.amts = data.withdrawAmts;
                depositAmts = _aaveV2Withdraw(_aaveV2WithdrawData);
            }
            _compDeposit(length, data.collateralFee, _ctokens, tokens, depositAmts);
        } else if (data.source == Protocol.Compound && data.target == Protocol.Aave) {

            AaveV1BorrowData memory _aaveV1BorrowData;

            _aaveV1BorrowData.aave = aaveV1;
            _aaveV1BorrowData.length = length;
            _aaveV1BorrowData.fee = data.debtFee;
            _aaveV1BorrowData.target = data.source;
            _aaveV1BorrowData.tokens = tokens;
            _aaveV1BorrowData.ctokens = _ctokens;
            _aaveV1BorrowData.amts = data.borrowAmts;
            _aaveV1BorrowData.borrowRateModes = data.borrowRateModes;
            _aaveV1BorrowData.paybackRateModes = data.paybackRateModes;
            
            paybackAmts = _aaveV1Borrow(_aaveV1BorrowData);
            {
            _compPayback(length, _ctokens, tokens, paybackAmts);
            depositAmts = _compWithdraw(length, _ctokens, tokens, data.withdrawAmts);
            }

            {
                AaveV1DepositData memory _aaveV1DepositData;
                
                _aaveV1DepositData.aave = aaveV1;
                _aaveV1DepositData.aaveCore = aaveCore;
                _aaveV1DepositData.length = length;
                _aaveV1DepositData.fee = data.collateralFee;
                _aaveV1DepositData.tokens = tokens;
                _aaveV1DepositData.amts = depositAmts;

                _aaveV1Deposit(_aaveV1DepositData);
            }
        } else if (data.source == Protocol.Compound && data.target == Protocol.AaveV2) {
            AaveV2BorrowData memory _aaveV2BorrowData;

            _aaveV2BorrowData.aave = aaveV2;
            _aaveV2BorrowData.length = length;
            _aaveV2BorrowData.fee = data.debtFee;
            _aaveV2BorrowData.target = data.source;
            _aaveV2BorrowData.tokens = tokens;
            _aaveV2BorrowData.ctokens = _ctokens;
            _aaveV2BorrowData.amts = data.borrowAmts;
            _aaveV2BorrowData.rateModes = data.borrowRateModes;
            
            paybackAmts = _aaveV2Borrow(_aaveV2BorrowData);
            _compPayback(length, _ctokens, tokens, paybackAmts);
            depositAmts = _compWithdraw(length, _ctokens, tokens, data.withdrawAmts);
            _aaveV2Deposit(aaveV2, aaveData, length, data.collateralFee, tokens, depositAmts);
        } else {
            revert("invalid-options");
        }
    }
}

contract ConnectV2Refinance is RefinanceResolver {
    string public name = "Refinance-v1.0";
}