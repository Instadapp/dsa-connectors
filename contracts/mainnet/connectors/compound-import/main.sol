pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { TokenInterface, AccountInterface } from "../../common/interfaces.sol";
import { CTokenInterface } from "./interface.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

// 1. Get info for all the assets the user has supplied as collateral and the assets he borrowed.
// 2. Take the flash loan for all the borrowed assets.
// 3. Using this flash loan, pay back the user's debt in the EOA account.
// 4. After paying the debt, transfer the user's tokens from EOA to DSA.
// 5. Then borrow debt of same tokens but include flash loan fee in it.
// 6. Payback the flash loan for all the tokens.

// fill logics in contract functions
contract FlashLoanHelper is Helpers, Events {
    function _flashLoan(
        address[] memory _tokens,
        uint256[] memory _amts
    ) internal {
        // fill in logic for flash loans
    }

    function _repayFlashLoan(
        address[] memory _tokens,
        uint256[] memory _amts
    ) internal {
        // fill in logic for flash loan repayment
    }
}

contract CompoundResolver is Helpers, Events {
    function _repayUserDebt(
        address _userAccount,
        CTokenInterface[] memory _cTokenContracts,
        uint[] memory _borrowAmts
    ) internal {
        for(uint i = 0; i < _cTokenContracts.length; i++){
            if(_borrowAmts[i] > 0){
                if(address(_cTokenContracts[i]) == address(cEth)){
                    cEth.repayBorrowBehalf{value: _borrowAmts[i]}(_userAccount);
                }
                else{
                    require(_cTokenContracts[i].repayBorrowBehalf(_userAccount, _borrowAmts[i]) == 0, "repayOnBehalf-failed");
                }
            }
        }
    }

    function _transferTokensToDsa(
        address _userAccount, 
        CTokenInterface[] memory _cTokenContracts,
        uint[] memory _amts
    ) internal {
        for(uint i = 0; i < _cTokenContracts.length; i++) {
            if(_amts[i] > 0) {
                require(_cTokenContracts[i].transferFrom(_userAccount, address(this), _amts[i]), "ctoken-transfer-failed-allowance?");
            }
        }
    }

    function _borrowDebtPosition(
        CTokenInterface[] memory _ctokenContracts, 
        uint[] memory _amts
    ) internal {
        for (uint i = 0; i < _ctokenContracts.length; i++) {
            if (_amts[i] > 0) {
            // add _amts flash loan fees to _amts[i]
                require(_ctokenContracts[i].borrow(_amts[i]) == 0, "borrow-failed-collateral?");
            }
        }        
    }
}

contract CompoundHelpers is CompoundResolver {
    struct ImportData {
        address[] cTokens; // is the list of all tokens the user has interacted with (supply/borrow) -> used to enter markets
        uint[] borrowAmts;
        uint[] supplyAmts;
        address[] borrowTokens;
        address[] supplyTokens;
        CTokenInterface[] borrowCtokens;
        CTokenInterface[] supplyCtokens;
        address[] supplyCtokensAddr;
        address[] borrowCtokensAddr;
    }

    struct ImportInputData {
        address userAccount;
        string[] supplyIds;
        string[] borrowIds;
    }

    function getBorrowAmounts (
        ImportInputData memory _importInputData,
        ImportData memory data
    ) internal returns(ImportData memory) {
        if (_importInputData.borrowIds.length > 0) {
            // initialize arrays for borrow data
            data.borrowTokens = new address[](_importInputData.borrowIds.length);
            data.borrowCtokens = new CTokenInterface[](_importInputData.borrowIds.length);
            data.borrowCtokensAddr = new address[](_importInputData.borrowIds.length);
            data.borrowAmts = new uint[](_importInputData.borrowIds.length);

            // check for repeated tokens
            for (uint i = 0; i < _importInputData.borrowIds.length; i++) {
                bytes32 i_hash = keccak256(abi.encode(_importInputData.borrowIds[i]));
                for (uint j = i + 1; j < _importInputData.borrowIds.length; j++) {
                    bytes32 j_hash = keccak256(abi.encode(_importInputData.borrowIds[j]));
                    require(i_hash != j_hash, "token-repeated");
                }
            }

            // populate the arrays with borrow tokens, cToken addresses and instances, and borrow amounts
            for (uint i = 0; i < _importInputData.borrowIds.length; i++) {
                (address _token, address _cToken) = compMapping.getMapping(_importInputData.borrowIds[i]);

                require(_token != address(0) && _cToken != address(0), "ctoken mapping not found");

                data.cTokens[i] = _cToken;

                data.borrowTokens[i] = _token;
                data.borrowCtokens[i] = CTokenInterface(_cToken);
                data.borrowCtokensAddr[i] = _cToken;
                data.borrowAmts[i] = data.borrowCtokens[i].borrowBalanceCurrent(_importInputData.userAccount);

                // give the resp. cToken address approval to spend tokens
                if (_token != ethAddr && data.borrowAmts[i] > 0) {
                    // will be required when repaying the borrow amount on behalf of the user
                    TokenInterface(_token).approve(_cToken, data.borrowAmts[i]);
                }
            }
        }
        return data;
    }

    function getSupplyAmounts (
        ImportInputData memory _importInputData,
        ImportData memory data
    ) internal view returns(ImportData memory) {
        // initialize arrays for supply data
        data.supplyTokens = new address[](_importInputData.supplyIds.length);
        data.supplyCtokens = new CTokenInterface[](_importInputData.supplyIds.length);
        data.supplyCtokensAddr = new address[](_importInputData.supplyIds.length);
        data.supplyAmts = new uint[](_importInputData.supplyIds.length);

        // check for repeated tokens
        for (uint i = 0; i < _importInputData.supplyIds.length; i++) {
            bytes32 i_hash = keccak256(abi.encode(_importInputData.supplyIds[i]));
            for (uint j = i + 1; j < _importInputData.supplyIds.length; j++) {
                bytes32 j_hash = keccak256(abi.encode(_importInputData.supplyIds[j]));
                require(i_hash != j_hash, "token-repeated");
            }
        }

        // populate arrays with supply data (supply tokens address, cToken addresses, cToken instances and supply amounts)
        for (uint i = 0; i < _importInputData.supplyIds.length; i++) {
            (address _token, address _cToken) = compMapping.getMapping(_importInputData.supplyIds[i]);
            
            require(_token != address(0) && _cToken != address(0), "ctoken mapping not found");

            uint _supplyIndex = add(i, _importInputData.borrowIds.length);
            data.cTokens[_supplyIndex] = _cToken;

            data.supplyTokens[i] = _token;
            data.supplyCtokens[i] = CTokenInterface(_cToken);
            data.supplyCtokensAddr[i] = (_cToken);
            data.supplyAmts[i] = data.supplyCtokens[i].balanceOf(_importInputData.userAccount);
        }
        return data;
    }
}

contract CompoundImportResolver is CompoundHelpers, FlashLoanHelper {

    // get info for all the assets the user has supplied as collateral and the assets borrowed
    function _importCompound(
        ImportInputData memory importInputData
    ) internal returns (string memory _eventName, bytes memory _eventParam) {
        require(AccountInterface(address(this)).isAuth(importInputData.userAccount), "user-account-not-auth");

        require(importInputData.supplyIds.length > 0, "0-length-not-allowed");

        ImportData memory data;

        uint _length = add(importInputData.supplyIds.length, importInputData.borrowIds.length);
        data.cTokens = new address[](_length);

        data = getBorrowAmounts(importInputData, data);
        data = getSupplyAmounts(importInputData, data);

        for(uint i = 0; i < data.cTokens.length; i++){
            enterMarket(data.cTokens[i]);
        }

        // take flash loan for all the borrowed assets
        // use the addresses of the borrowed tokens and their amounts to get the same flash loans
        _flashLoan(data.borrowTokens, data.borrowAmts);

        // pay back user's debt using flash loan funds
        _repayUserDebt(importInputData.userAccount, data.borrowCtokens, data.borrowAmts);

        // transfer user's tokens to DSA
        _transferTokensToDsa(importInputData.userAccount, data.supplyCtokens, data.supplyAmts);

        // borrow the earlier position from Compound with flash loan fee added
        _borrowDebtPosition(data.borrowCtokens, data.borrowAmts);

        // payback flash loan 
        _repayFlashLoan(data.borrowTokens, data.borrowAmts); // update borrowAmounts with flash loan fee

        _eventName = "LogCompoundImport(address,address[],string[],string[],uint256[],uint256[])";
        _eventParam = abi.encode(
            importInputData.userAccount,
            data.cTokens,
            importInputData.supplyIds,
            importInputData.borrowIds,
            data.supplyAmts,
            data.borrowAmts
        );
    }

    function importCompound(
        address userAccount,
        string[] memory supplyIds,
        string[] memory borrowIds
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        ImportInputData memory inputData = ImportInputData({
            userAccount: userAccount,
            supplyIds: supplyIds,
            borrowIds: borrowIds
        }); 

        (_eventName, _eventParam) = _importCompound(inputData);
    }

    function migrateCompound(
        string[] memory supplyIds,
        string[] memory borrowIds
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        ImportInputData memory inputData = ImportInputData({
            userAccount: msg.sender,
            supplyIds: supplyIds,
            borrowIds: borrowIds
        });

        (_eventName, _eventParam) = _importCompound(inputData);
    }
}
