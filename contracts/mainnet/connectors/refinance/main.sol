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

    struct RefinanceInternalData {
        AaveV2Interface aaveV2;
        AaveV1Interface aaveV1;
        AaveV1CoreInterface aaveCore;
        AaveV2DataProviderInterface aaveData;
        uint[] depositAmts;
        uint[] paybackAmts;
        TokenInterface[] tokens;
        CTokenInterface[] _ctokens;
    }

    function _refinance(RefinanceData calldata data) 
        internal returns (string memory _eventName, bytes memory _eventParam)
    {

        require(data.source != data.target, "source-and-target-unequal");

        uint length = data.tokens.length;

        require(data.borrowAmts.length == length, "length-mismatch");
        require(data.withdrawAmts.length == length, "length-mismatch");
        require(data.borrowRateModes.length == length, "length-mismatch");
        require(data.paybackRateModes.length == length, "length-mismatch");
        require(data.ctokenIds.length == length, "length-mismatch");

        RefinanceInternalData memory refinanceInternalData;

        refinanceInternalData.aaveV2 = AaveV2Interface(getAaveV2Provider.getLendingPool());
        refinanceInternalData.aaveV1 = AaveV1Interface(getAaveProvider.getLendingPool());
        refinanceInternalData.aaveCore = AaveV1CoreInterface(getAaveProvider.getLendingPoolCore());
        refinanceInternalData.aaveData = getAaveV2DataProvider;

        refinanceInternalData.depositAmts;
        refinanceInternalData.paybackAmts;

        refinanceInternalData.tokens = getTokenInterfaces(length, data.tokens);
        refinanceInternalData._ctokens = getCtokenInterfaces(length, data.ctokenIds);

        if (data.source == Protocol.Aave && data.target == Protocol.AaveV2) {
            AaveV2BorrowData memory _aaveV2BorrowData;

            _aaveV2BorrowData.aave = refinanceInternalData.aaveV2;
            _aaveV2BorrowData.length = length;
            _aaveV2BorrowData.fee = data.debtFee;
            _aaveV2BorrowData.target = data.source;
            _aaveV2BorrowData.tokens = refinanceInternalData.tokens;
            _aaveV2BorrowData.ctokens = refinanceInternalData._ctokens;
            _aaveV2BorrowData.amts = data.borrowAmts;
            _aaveV2BorrowData.rateModes = data.borrowRateModes;
            {
            refinanceInternalData.paybackAmts = _aaveV2Borrow(_aaveV2BorrowData);
            _aaveV1Payback(
                refinanceInternalData.aaveV1,
                refinanceInternalData.aaveCore,
                length,
                refinanceInternalData.tokens,
                refinanceInternalData.paybackAmts
            );
            refinanceInternalData.depositAmts = _aaveV1Withdraw(
                refinanceInternalData.aaveV1,
                refinanceInternalData.aaveCore,
                length,
                refinanceInternalData.tokens,
                data.withdrawAmts
            );
            _aaveV2Deposit(
                refinanceInternalData.aaveV2,
                refinanceInternalData.aaveData,
                length,
                data.collateralFee,
                refinanceInternalData.tokens,
                refinanceInternalData.depositAmts
            );
            }
        } else if (data.source == Protocol.Aave && data.target == Protocol.Compound) {
            _compEnterMarkets(length, refinanceInternalData._ctokens);

            CompoundBorrowData memory _compoundBorrowData;

            _compoundBorrowData.length = length;
            _compoundBorrowData.fee = data.debtFee;
            _compoundBorrowData.target = data.source;
            _compoundBorrowData.ctokens = refinanceInternalData._ctokens;
            _compoundBorrowData.tokens = refinanceInternalData.tokens;
            _compoundBorrowData.amts = data.borrowAmts;
            _compoundBorrowData.rateModes = data.borrowRateModes;

            refinanceInternalData.paybackAmts = _compBorrow(_compoundBorrowData);
            
            _aaveV1Payback(
                refinanceInternalData.aaveV1,
                refinanceInternalData.aaveCore,
                length,
                refinanceInternalData.tokens,
                refinanceInternalData.paybackAmts
            );
            refinanceInternalData.depositAmts = _aaveV1Withdraw(
                refinanceInternalData.aaveV1,
                refinanceInternalData.aaveCore,
                length,
                refinanceInternalData.tokens, 
                data.withdrawAmts
            );
            _compDeposit(
                length,
                data.collateralFee,
                refinanceInternalData._ctokens,
                refinanceInternalData.tokens,
                refinanceInternalData.depositAmts
            );
        } else if (data.source == Protocol.AaveV2 && data.target == Protocol.Aave) {

            AaveV1BorrowData memory _aaveV1BorrowData;
            AaveV2PaybackData memory _aaveV2PaybackData;
            AaveV2WithdrawData memory _aaveV2WithdrawData;

            {
                _aaveV1BorrowData.aave = refinanceInternalData.aaveV1;
                _aaveV1BorrowData.length = length;
                _aaveV1BorrowData.fee = data.debtFee;
                _aaveV1BorrowData.target = data.source;
                _aaveV1BorrowData.tokens = refinanceInternalData.tokens;
                _aaveV1BorrowData.ctokens = refinanceInternalData._ctokens;
                _aaveV1BorrowData.amts = data.borrowAmts;
                _aaveV1BorrowData.borrowRateModes = data.borrowRateModes;
                _aaveV1BorrowData.paybackRateModes = data.paybackRateModes;

                refinanceInternalData.paybackAmts = _aaveV1Borrow(_aaveV1BorrowData);
            }
            
            {
                _aaveV2PaybackData.aave = refinanceInternalData.aaveV2;
                _aaveV2PaybackData.aaveData = refinanceInternalData.aaveData;
                _aaveV2PaybackData.length = length;
                _aaveV2PaybackData.tokens = refinanceInternalData.tokens;
                _aaveV2PaybackData.amts = refinanceInternalData.paybackAmts;
                _aaveV2PaybackData.rateModes = data.paybackRateModes;
                _aaveV2Payback(_aaveV2PaybackData);
            }

            {
                _aaveV2WithdrawData.aave = refinanceInternalData.aaveV2;
                _aaveV2WithdrawData.aaveData = refinanceInternalData.aaveData;
                _aaveV2WithdrawData.length = length;
                _aaveV2WithdrawData.tokens = refinanceInternalData.tokens;
                _aaveV2WithdrawData.amts = data.withdrawAmts;
                refinanceInternalData.depositAmts = _aaveV2Withdraw(_aaveV2WithdrawData);
            }
            {
                AaveV1DepositData memory _aaveV1DepositData;
                
                _aaveV1DepositData.aave = refinanceInternalData.aaveV1;
                _aaveV1DepositData.aaveCore = refinanceInternalData.aaveCore;
                _aaveV1DepositData.length = length;
                _aaveV1DepositData.fee = data.collateralFee;
                _aaveV1DepositData.tokens = refinanceInternalData.tokens;
                _aaveV1DepositData.amts = refinanceInternalData.depositAmts;

                _aaveV1Deposit(_aaveV1DepositData);
            }
        } else if (data.source == Protocol.AaveV2 && data.target == Protocol.Compound) {
            _compEnterMarkets(length, refinanceInternalData._ctokens);

            {
                CompoundBorrowData memory _compoundBorrowData;

                _compoundBorrowData.length = length;
                _compoundBorrowData.fee = data.debtFee;
                _compoundBorrowData.target = data.source;
                _compoundBorrowData.ctokens = refinanceInternalData._ctokens;
                _compoundBorrowData.tokens = refinanceInternalData.tokens;
                _compoundBorrowData.amts = data.borrowAmts;
                _compoundBorrowData.rateModes = data.borrowRateModes;

                refinanceInternalData.paybackAmts = _compBorrow(_compoundBorrowData);
            }

            AaveV2PaybackData memory _aaveV2PaybackData;

            _aaveV2PaybackData.aave = refinanceInternalData.aaveV2;
            _aaveV2PaybackData.aaveData = refinanceInternalData.aaveData;
            _aaveV2PaybackData.length = length;
            _aaveV2PaybackData.tokens = refinanceInternalData.tokens;
            _aaveV2PaybackData.amts = refinanceInternalData.paybackAmts;
            _aaveV2PaybackData.rateModes = data.paybackRateModes;
            
            _aaveV2Payback(_aaveV2PaybackData);

            {
                AaveV2WithdrawData memory _aaveV2WithdrawData;

                _aaveV2WithdrawData.aave = refinanceInternalData.aaveV2;
                _aaveV2WithdrawData.aaveData = refinanceInternalData.aaveData;
                _aaveV2WithdrawData.length = length;
                _aaveV2WithdrawData.tokens = refinanceInternalData.tokens;
                _aaveV2WithdrawData.amts = data.withdrawAmts;
                refinanceInternalData.depositAmts = _aaveV2Withdraw(_aaveV2WithdrawData);
            }
            _compDeposit(
                length,
                data.collateralFee,
                refinanceInternalData._ctokens,
                refinanceInternalData.tokens,
                refinanceInternalData.depositAmts
            );
        } else if (data.source == Protocol.Compound && data.target == Protocol.Aave) {

            AaveV1BorrowData memory _aaveV1BorrowData;

            _aaveV1BorrowData.aave = refinanceInternalData.aaveV1;
            _aaveV1BorrowData.length = length;
            _aaveV1BorrowData.fee = data.debtFee;
            _aaveV1BorrowData.target = data.source;
            _aaveV1BorrowData.tokens = refinanceInternalData.tokens;
            _aaveV1BorrowData.ctokens = refinanceInternalData._ctokens;
            _aaveV1BorrowData.amts = data.borrowAmts;
            _aaveV1BorrowData.borrowRateModes = data.borrowRateModes;
            _aaveV1BorrowData.paybackRateModes = data.paybackRateModes;
            
            refinanceInternalData.paybackAmts = _aaveV1Borrow(_aaveV1BorrowData);
            {
            _compPayback(
                length,
                refinanceInternalData._ctokens,
                refinanceInternalData.tokens,
                refinanceInternalData.paybackAmts
            );
            refinanceInternalData.depositAmts = _compWithdraw(
                length,
                refinanceInternalData._ctokens,
                refinanceInternalData.tokens,
                data.withdrawAmts
            );
            }

            {
                AaveV1DepositData memory _aaveV1DepositData;
                
                _aaveV1DepositData.aave = refinanceInternalData.aaveV1;
                _aaveV1DepositData.aaveCore = refinanceInternalData.aaveCore;
                _aaveV1DepositData.length = length;
                _aaveV1DepositData.fee = data.collateralFee;
                _aaveV1DepositData.tokens = refinanceInternalData.tokens;
                _aaveV1DepositData.amts = refinanceInternalData.depositAmts;

                _aaveV1Deposit(_aaveV1DepositData);
            }
        } else if (data.source == Protocol.Compound && data.target == Protocol.AaveV2) {
            AaveV2BorrowData memory _aaveV2BorrowData;

            _aaveV2BorrowData.aave = refinanceInternalData.aaveV2;
            _aaveV2BorrowData.length = length;
            _aaveV2BorrowData.fee = data.debtFee;
            _aaveV2BorrowData.target = data.source;
            _aaveV2BorrowData.tokens = refinanceInternalData.tokens;
            _aaveV2BorrowData.ctokens = refinanceInternalData._ctokens;
            _aaveV2BorrowData.amts = data.borrowAmts;
            _aaveV2BorrowData.rateModes = data.borrowRateModes;
            
            refinanceInternalData.paybackAmts = _aaveV2Borrow(_aaveV2BorrowData);
            _compPayback(length, refinanceInternalData._ctokens, refinanceInternalData.tokens, refinanceInternalData.paybackAmts);
            refinanceInternalData.depositAmts = _compWithdraw(
                length,
                refinanceInternalData._ctokens,
                refinanceInternalData.tokens,
                data.withdrawAmts
            );
            _aaveV2Deposit(
                refinanceInternalData.aaveV2,
                refinanceInternalData.aaveData,
                length,
                data.collateralFee,
                refinanceInternalData.tokens,
                refinanceInternalData.depositAmts
            );
        } else {
            revert("invalid-options");
        }
    }



    /**
     * @dev Refinance
     * @notice Refinancing between AaveV1, AaveV2 and Compound
     * @param data refinance data.
    */
    function refinance(RefinanceData calldata data) 
        external payable returns (string memory _eventName, bytes memory _eventParam) {
        (_eventName, _eventParam) = _refinance(data);
    }
}

contract ConnectV2Refinance is RefinanceResolver {
    string public name = "Refinance-v1.1";
}