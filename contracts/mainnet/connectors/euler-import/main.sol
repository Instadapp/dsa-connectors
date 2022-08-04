//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./helpers.sol";

contract EulerImport is EulerHelpers {

    /**
	 * @dev Import Euler position.
	 * @notice Import EOA's Euler subaccount position to DSA's Euler subaccount
	 * @param userAccount The address of the EOA from which position will be imported
     * @param sourceId EOA sub-account id from which position be be imported
     * @param targetId DSA sub-account id
	 * @param inputData The struct containing all the neccessary input data
	 * @param enterMarket The boolean array to enable market in the imported position
	 */
	function importEuler(
        address userAccount,
        uint256 sourceId, 
        uint256 targetId,
        ImportInputData memory inputData,
        bool[] memory enterMarket
    )
		external
		payable
        returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importEuler(userAccount, sourceId, targetId, inputData, enterMarket);
	}

    function _importEuler(
        address userAccount,
        uint256 sourceId, 
        uint256 targetId,
        ImportInputData memory inputData,
        bool[] memory enterMarket
    )
		internal
        returns (string memory _eventName, bytes memory _eventParam)
	{
        require(
			AccountInterface(address(this)).isAuth(userAccount),
			"user-account-not-auth"
		);
		require(inputData.supplyTokens.length > 0, "0-length-not-allowed");
        require(enterMarket.length == inputData.supplyTokens.length, "lengths-not-same");

        address _sourceAccount = getSubAccountAddress(userAccount, sourceId);
        address _targetAccount = getSubAccountAddress(address(this), targetId);

		ImportData memory data;

        data = getBorrowAmounts(_sourceAccount, inputData, data);
		data = getSupplyAmounts(_targetAccount, inputData, data);
        
        IEulerExecute(eulerExec).deferLiquidityCheck(_sourceAccount, "0x0");

        _TransferEtokens(
			data._supplyTokens.length,
			data.eTokens,
			data.supplyAmts,
			data._supplyTokens,
			enterMarket,
			_sourceAccount,
            _targetAccount,
            targetId
		);

        _TransferDtokens(
            data._borrowTokens.length,
            data.dTokens,
            data.borrowAmts,
            data._borrowTokens,
            _sourceAccount,
            _targetAccount
        );

        _eventName = "LogEulerImport(address,uint256,uint256,address[],address[],uint256[],uint256[],bool[])";
		_eventParam = abi.encode(
			userAccount,
            sourceId,
            targetId,
            inputData.supplyTokens,
			inputData.borrowTokens,
            data.supplyAmts,
			data.borrowAmts,
            enterMarket
		);
    }
}

contract ConnectV2EulerImport is EulerImport {
	string public constant name = "Euler-import-v1.0";
}
