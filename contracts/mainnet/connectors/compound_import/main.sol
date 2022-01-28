pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { TokenInterface, AccountInterface } from "../../../../common/interfaces.sol";
import { CTokenInterface } from "./interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";


contract CompoundResolver is Helpers, Events {
    function _borrow(CTokenInterface[] memory ctokenContracts, uint[] memory amts, uint _length) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                require(ctokenContracts[i].borrow(amts[i]) == 0, "borrow-failed-collateral?");
            }
        }
    }

    function _paybackOnBehalf(
        address userAddress,
        CTokenInterface[] memory ctokenContracts,
        uint[] memory amts,
        uint _length
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                if (address(ctokenContracts[i]) == address(ceth)) {
                    ceth.repayBorrowBehalf{value: amts[i]}(userAddress);
                } else {
                    require(ctokenContracts[i].repayBorrowBehalf(userAddress, amts[i]) == 0, "repayOnBehalf-failed");
                }
            }
        }
    }

    function _transferCtokens(
        address userAccount,
        CTokenInterface[] memory ctokenContracts,
        uint[] memory amts,
        uint _length
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                // console.log("_transferCtokens", ctokenContracts[i].allowance(userAccount, address(this)), amts[i], ctokenContracts[i].balanceOf(userAccount));
                require(ctokenContracts[i].transferFrom(userAccount, address(this), amts[i]), "ctoken-transfer-failed-allowance?");
            }
        }
    }
}

contract CompoundHelpers is CompoundResolver {
    struct ImportData {
        uint[] supplyAmts;
        uint[] borrowAmts;
        uint[] supplySplitAmts;
        uint[] borrowSplitAmts;
        uint[] supplyFinalAmts;
        uint[] borrowFinalAmts;
        uint[] borrowFinalAmtsWithFee;
        address[] ctokens;
        CTokenInterface[] supplyCtokens;
        CTokenInterface[] borrowCtokens;
        address[] supplyCtokensAddr;
        address[] borrowCtokensAddr;
    }

    struct ImportInputData {
        address userAccount;
        string[] supplyIds;
        string[] borrowIds;
        uint256 times;
        bool isFlash;
        uint[] flashFees;
    }

    function getBorrowAmounts (
        ImportInputData memory importInputData,
        ImportData memory data
    ) internal returns(ImportData memory) {
        if (importInputData.borrowIds.length > 0) {
            data.borrowAmts = new uint[](importInputData.borrowIds.length);
            data.borrowCtokens = new CTokenInterface[](importInputData.borrowIds.length);
            data.borrowSplitAmts = new uint[](importInputData.borrowIds.length);
            data.borrowFinalAmts = new uint[](importInputData.borrowIds.length);
            data.borrowFinalAmtsWithFee = new uint[](importInputData.borrowIds.length);
            data.borrowCtokensAddr = new address[](importInputData.borrowIds.length);

            for (uint i = 0; i < importInputData.borrowIds.length; i++) {
                bytes32 i_hash = keccak256(abi.encode(importInputData.borrowIds[i]));
                for (uint j = i; j < importInputData.borrowIds.length; j++) {
                    bytes32 j_hash = keccak256(abi.encode(importInputData.borrowIds[j]));
                    if (j != i) {
                        require(i_hash != j_hash, "token-repeated");
                    }
                }
            }

            if (importInputData.times > 0) {
                for (uint i = 0; i < importInputData.borrowIds.length; i++) {
                    (address _token, address _ctoken) = compMapping.getMapping(importInputData.borrowIds[i]);
                    require(_token != address(0) && _ctoken != address(0), "ctoken mapping not found");

                    data.ctokens[i] = _ctoken;

                    data.borrowCtokens[i] = CTokenInterface(_ctoken);
                    data.borrowCtokensAddr[i] = (_ctoken);
                    data.borrowAmts[i] = data.borrowCtokens[i].borrowBalanceCurrent(importInputData.userAccount);

                    if (_token != ethAddr && data.borrowAmts[i] > 0) {
                        TokenInterface(_token).approve(_ctoken, data.borrowAmts[i]);
                    }

                    if (importInputData.times == 1) {
                        data.borrowFinalAmts = data.borrowAmts;
                        data.borrowFinalAmtsWithFee[i] = data.borrowFinalAmts[i] + importInputData.flashFees[i];
                    } else {
                        data.borrowSplitAmts[i] = data.borrowAmts[i] / importInputData.times;
                        data.borrowFinalAmts[i] = sub(data.borrowAmts[i], mul(data.borrowSplitAmts[i], sub(importInputData.times, 1)));
                        data.borrowFinalAmtsWithFee[i] = add(data.borrowFinalAmts[i], importInputData.flashFees[i]);
                    }

                }
            }
        }
        return data;
    }
    
    function getSupplyAmounts (
        ImportInputData memory importInputData,
        ImportData memory data
    ) internal view returns(ImportData memory) {
        data.supplyAmts = new uint[](importInputData.supplyIds.length);
        data.supplyCtokens = new CTokenInterface[](importInputData.supplyIds.length);
        data.supplySplitAmts = new uint[](importInputData.supplyIds.length);
        data.supplyFinalAmts = new uint[](importInputData.supplyIds.length);
        data.supplyCtokensAddr = new address[](importInputData.supplyIds.length);

        for (uint i = 0; i < importInputData.supplyIds.length; i++) {
            bytes32 i_hash = keccak256(abi.encode(importInputData.supplyIds[i]));
            for (uint j = i; j < importInputData.supplyIds.length; j++) {
                bytes32 j_hash = keccak256(abi.encode(importInputData.supplyIds[j]));
                if (j != i) {
                    require(i_hash != j_hash, "token-repeated");
                }
            }
        }

        for (uint i = 0; i < importInputData.supplyIds.length; i++) {
            (address _token, address _ctoken) = compMapping.getMapping(importInputData.supplyIds[i]);
            require(_token != address(0) && _ctoken != address(0), "ctoken mapping not found");

            uint _supplyIndex = add(i, importInputData.borrowIds.length);

            data.ctokens[_supplyIndex] = _ctoken;

            data.supplyCtokens[i] = CTokenInterface(_ctoken);
            data.supplyCtokensAddr[i] = (_ctoken);
            data.supplyAmts[i] = data.supplyCtokens[i].balanceOf(importInputData.userAccount);

            if ((importInputData.times == 1 && importInputData.isFlash) || importInputData.times == 0) {
                data.supplyFinalAmts = data.supplyAmts;
            } else {
                for (uint j = 0; j < data.supplyAmts.length; j++) {
                    uint _times = importInputData.isFlash ? importInputData.times : importInputData.times + 1;
                    data.supplySplitAmts[j] = data.supplyAmts[j] / _times;
                    data.supplyFinalAmts[j] = sub(data.supplyAmts[j], mul(data.supplySplitAmts[j], sub(_times, 1)));
                }

            }
        }
        return data;
    }

}

contract CompoundImportResolver is CompoundHelpers {

    function _importCompound(
        ImportInputData memory importInputData
    ) internal returns (string memory _eventName, bytes memory _eventParam) {
        require(AccountInterface(address(this)).isAuth(importInputData.userAccount), "user-account-not-auth");

        require(importInputData.supplyIds.length > 0, "0-length-not-allowed");

        ImportData memory data;

        uint _length = add(importInputData.supplyIds.length, importInputData.borrowIds.length);
        data.ctokens = new address[](_length);
    
        data = getBorrowAmounts(importInputData, data);
        data = getSupplyAmounts(importInputData, data);

        enterMarkets(data.ctokens);

        _borrow(data.borrowCtokens, data.borrowFinalAmts, importInputData.borrowIds.length);
        _paybackOnBehalf(importInputData.userAccount, data.borrowCtokens, data.borrowFinalAmtsWithFee, importInputData.borrowIds.length);
        _transferCtokens(importInputData.userAccount, data.supplyCtokens, data.supplyFinalAmts, importInputData.supplyIds.length);

        _eventName = "LogCompoundImport(address,address[],string[],string[],uint256[],uint256[])";
        _eventParam = abi.encode(
            importInputData.userAccount,
            data.ctokens,
            importInputData.supplyIds,
            importInputData.borrowIds,
            data.supplyAmts,
            data.borrowAmts
        );
    }

    function importCompound(
        address userAccount,
        string[] memory supplyIds,
        string[] memory borrowIds,
        uint[] memory flashFees,
        uint256 times,
        bool isFlash
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        ImportInputData memory inputData = ImportInputData({
            userAccount: userAccount,
            supplyIds: supplyIds,
            borrowIds: borrowIds,
            times: times,
            isFlash: isFlash,
            flashFees: flashFees
        });

        (_eventName, _eventParam) = _importCompound(inputData);
    }

    function migrateCompound(
        string[] memory supplyIds,
        string[] memory borrowIds,
        uint256 times,
        bool isFlash,
        uint[] memory flashFees
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        ImportInputData memory inputData = ImportInputData({
            userAccount: msg.sender,
            supplyIds: supplyIds,
            borrowIds: borrowIds,
            times: times,
            isFlash: isFlash,
            flashFees: flashFees
        });

        (_eventName, _eventParam) = _importCompound(inputData);
    }
}

contract ConnectV2CompoundImport is CompoundImportResolver {

    string public constant name = "Compound-Import-v2";
}
