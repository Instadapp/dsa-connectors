pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { TokenInterface, AccountInterface } from "../../common/interfaces.sol";
import { CompoundHelper } from "./helpers.sol";
import { Events } from "./events.sol";

// 1. Get info for all the assets the user has supplied as collateral and the assets he borrowed.
// 2. Using the flash loan funds, pay back the user's debt in the EOA account.
// 3. After paying the debt, transfer the user's tokens from EOA to DSA.
// 4. Then borrow debt of same tokens but include flash loan fee in it.

contract CompoundImportResolver is CompoundHelper {

    /**
     * @notice this function performs the import of user's Compound positions into its DSA
     * @dev called internally by the importCompound and migrateCompound functions
     * @param _importInputData the struct containing borrowIds of the users borrowed tokens
     * @param _flashLoanFee flash loan fee
     */
    function _importCompound(
        ImportInputData memory _importInputData,
        uint256 _flashLoanFee
    ) internal returns (string memory _eventName, bytes memory _eventParam) {
        require(AccountInterface(address(this)).isAuth(_importInputData.userAccount), "user-account-not-auth");

        require(_importInputData.supplyIds.length > 0, "0-length-not-allowed");

        ImportData memory data;

        uint _length = add(_importInputData.supplyIds.length, _importInputData.borrowIds.length);
        data.cTokens = new address[](_length);

        // get info about all borrowings and lendings by the user on Compound
        data = getBorrowAmounts(_importInputData, data);
        data = getSupplyAmounts(_importInputData, data);

        for(uint i = 0; i < data.cTokens.length; i++){
            enterMarket(data.cTokens[i]);
        }

        // pay back user's debt using flash loan funds
        _repayUserDebt(_importInputData.userAccount, data.borrowCtokens, data.borrowAmts);

        // transfer user's tokens to DSA
        _transferTokensToDsa(_importInputData.userAccount, data.supplyCtokens, data.supplyAmts);

        // borrow the earlier position from Compound with flash loan fee added
        _borrowDebtPosition(data.borrowCtokens, data.borrowAmts, _flashLoanFee);

        _eventName = "LogCompoundImport(address,address[],string[],string[],uint256[],uint256[])";
        _eventParam = abi.encode(
            _importInputData.userAccount,
            data.cTokens,
            _importInputData.supplyIds,
            _importInputData.borrowIds,
            data.supplyAmts,
            data.borrowAmts
        );
    }

    /**
     * @notice import Compound position of the address passed in as userAccount
     * @dev internally calls _importContract to perform the actual import
     * @param _userAccount address of user whose position is to be imported to DSA
     * @param _supplyIds Ids of all tokens the user has supplied to Compound
     * @param _borrowIds Ids of all token borrowed by the user
     * @param _flashLoanFee flash loan fee (in percentage and scaled up to 10**2)
     */
    function importCompound(
        address _userAccount,
        string[] memory _supplyIds,
        string[] memory _borrowIds,
        uint256 _flashLoanFee
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        ImportInputData memory inputData = ImportInputData({
            userAccount: _userAccount,
            supplyIds: _supplyIds,
            borrowIds: _borrowIds
        }); 

        (_eventName, _eventParam) = _importCompound(inputData, _flashLoanFee);
    }

    /**
     * @notice import msg.sender's Compound position (which is the user since this is a delegateCall)
     * @dev internally calls _importContract to perform the actual import
     * @param _supplyIds Ids of all tokens the user has supplied to Compound
     * @param _borrowIds Ids of all token borrowed by the user
     * @param _flashLoanFee flash loan fee (in percentage and scaled up to 10**2)
     */
    function migrateCompound(
        string[] memory _supplyIds,
        string[] memory _borrowIds,
        uint256 _flashLoanFee
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        ImportInputData memory inputData = ImportInputData({
            userAccount: msg.sender,
            supplyIds: _supplyIds,
            borrowIds: _borrowIds
        });

        (_eventName, _eventParam) = _importCompound(inputData, _flashLoanFee);
    }
}

contract ConnectV2CompoundImport is CompoundImportResolver {
    string public constant name = "Compound-Import-v2";
}