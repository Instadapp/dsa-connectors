pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { TokenInterface, AccountInterface } from "../../common/interfaces.sol";
import { CTokenInterface } from "./interface.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

// 1. Get info for all the assets the user has supplied as collateral and the assets he borrowed.
// 2. Using the flash loan funds, pay back the user's debt in the EOA account.
// 3. After paying the debt, transfer the user's tokens from EOA to DSA.
// 4. Then borrow debt of same tokens but include flash loan fee in it.

contract CompoundHelper is Helpers, Events {
    /**
     * @notice repays the debt taken by user on Compound on its behalf to free its collateral for transfer
     * @dev uses the cEth contract for ETH repays, otherwise the general cToken interface
     * @param _userAccount the user address for which debt is to be repayed
     * @param _cTokenContracts array containing all interfaces to the cToken contracts in which the user has debt positions
     * @param _borrowAmts array containing the amount borrowed for each token
     */
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

    /**
     * @notice used to transfer user's supply position on Compound to DSA
     * @dev uses the transferFrom token in cToken contracts to transfer positions, requires approval from user first
     * @param _userAccount address of the user account whose position is to be transferred
     * @param _cTokenContracts array containing all interfaces to the cToken contracts in which the user has supply positions
     * @param _amts array containing the amount supplied for each token
     */
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

    /**
     * @notice borrows the user's debt positions from Compound via DSA, so that its debt positions get imported to DSA
     * @dev actually borrow some extra amount than the original position to cover the flash loan fee
     * @param _cTokenContracts array containing all interfaces to the cToken contracts in which the user has debt positions
     * @param _amts array containing the amounts the user had borrowed originally from Compound plus the flash loan fee
     * @param _flashLoanFee flash loan fee (in percentage and scaled up to 10**2)
     */
    function _borrowDebtPosition(
        CTokenInterface[] memory _cTokenContracts, 
        uint256[] memory _amts,
        uint256 _flashLoanFee
    ) internal {
        for (uint i = 0; i < _cTokenContracts.length; i++) {
            if (_amts[i] > 0) {
                require(_cTokenContracts[i].borrow(add(_amts[i], mul(_amts[i], mul(_flashLoanFee, 10**14)))) == 0, "borrow-failed-collateral?");
            }
        }        
    }
}

contract CompoundResolver is CompoundHelper {
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

    /**
     * @notice fetch the borrow details of the user
     * @dev approve the cToken to spend (borrowed amount of) tokens to allow for repaying later
     * @param _importInputData the struct containing borrowIds of the users borrowed tokens
     * @param data struct used to store the final data on which the CompoundHelper contract functions operate
     * @return ImportData the final value of param data
     */
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

    /**
     * @notice fetch the supply details of the user
     * @dev only reads data from blockchain hence view
     * @param _importInputData the struct containing supplyIds of the users supplied tokens
     * @param data struct used to store the final data on which the CompoundHelper contract functions operate
     * @return ImportData the final value of param data
     */
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

contract CompoundImport is CompoundResolver {

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

contract ConnectV2CompoundImport is CompoundImport {
    string public constant name = "Compound-Import-v2";
}