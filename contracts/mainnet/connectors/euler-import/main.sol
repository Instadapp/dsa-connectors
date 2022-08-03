//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./helpers.sol";

contract EulerImport is EulerHelpers {

	function importEuler(
        address userAccount,//EOA address
        uint256 sourceId, 
        uint256 targetId,
        bool[] memory enterMarket,
        ImportInputData memory inputData
    )
		external
		payable
	{
		_importEuler(userAccount, sourceId, targetId, inputData, enterMarket);
	}

    function _importEuler(
        address userAccount,//EOA address
        uint256 sourceId, 
        uint256 targetId,
        ImportInputData memory inputData,
        bool[] memory enterMarket
    )
		internal
	{
        require(
			AccountInterface(address(this)).isAuth(userAccount),
			"user-account-not-auth"
		);
		require(inputData.supplyTokens.length > 0, "0-length-not-allowed");
        require(enterMarket.length == inputData.supplyTokens.length, "lengths-not-same");

        address _sourceAccount = getSubAccountAddress(userAccount, sourceId); //User's EOA sub-account address
        address _targetAccount = getSubAccountAddress(address(this), targetId);

		ImportData memory data;

        data = getBorrowAmounts(_sourceAccount, inputData, data);
		data = getSupplyAmounts(_targetAccount, inputData, data);

        _TransferEtokens(
			data._supplyTokens.length,
			data.eTokens,
			data.supplyAmts,
			data._supplyTokens,
			enterMarket,
			_sourceAccount,
            _targetAccount
		);

        _TransferDtokens(
            data._borrowTokens.length,
            data.dTokens,
            data.borrowAmts,
            data._borrowTokens,
            _sourceAccount,
            _targetAccount
        );
    }
}
