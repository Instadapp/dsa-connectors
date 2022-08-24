//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./helpers.sol";
import "./interface.sol";
import "./events.sol";

contract EulerImport is EulerHelpers {

    /**
	 * @dev Import Euler position .
	 * @notice Import EOA's Euler position to DSA's Euler position
	 * @param userAccount The address of the EOA from which position will be imported
	 * @param sourceId sub-account id of EOA from which the funds will be transferred
     * @param targetId sub-account id of DSA to which the funds will be transferred
     * @param inputData The struct containing all the neccessary input data
	 */
    function importEuler(
        address userAccount,
        uint256 sourceId, 
        uint256 targetId,
        ImportInputData memory inputData
    )
		external
		payable
        returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importEuler(userAccount, sourceId, targetId, inputData);
	}

    struct importHelper {
        uint enterMarketLength;
        uint supplylength;
        uint borrowlength;
        uint totalLength;
    }

    /**
	 * @dev Import Euler position .
	 * @notice Import EOA's Euler position to DSA's Euler position
	 * @param userAccount The address of the EOA from which position will be imported
	 * @param sourceId sub-account id of EOA from which the funds will be transferred
     * @param targetId sub-account id of DSA to which the funds will be transferred
     * @param inputData The struct containing all the neccessary input data
	 */
    function _importEuler(
        address userAccount,
        uint256 sourceId, 
        uint256 targetId,
        ImportInputData memory inputData
    )
		internal
        returns (string memory _eventName, bytes memory _eventParam)
	{

        importHelper memory helper;

        require(
			AccountInterface(address(this)).isAuth(userAccount),
			"user-account-not-auth"
		);
		require(inputData.supplyTokens.length > 0, "0-length-not-allowed");

        ImportData memory data;

        helper.enterMarketLength = inputData.enterMarket.length;

        require(helper.enterMarketLength == inputData.supplyTokens.length, "lengths-not-same");

        address _sourceAccount = getSubAccountAddress(userAccount, sourceId);
        address _targetAccount = getSubAccountAddress(address(this), targetId);

        data = getBorrowAmounts(_sourceAccount, inputData, data);

        // In 18 dec 
		data = getSupplyAmounts(_sourceAccount, inputData, data);

        helper.supplylength = data._supplyTokens.length;
        helper.borrowlength = data._borrowTokens.length;
        uint count = 0;

        for(uint i = 0; i < helper.enterMarketLength; i++) {
           count = inputData.enterMarket[i] ? count++ : count;
        }

        helper.totalLength = count + helper.supplylength + helper.borrowlength;

        IEulerExecute.EulerBatchItem[] memory items = new IEulerExecute.EulerBatchItem[](helper.totalLength);

        uint k = 0;

        for(uint i = 0; i < helper.supplylength; i++) {

            items[k] = IEulerExecute.EulerBatchItem({
                allowError: false,
                proxyAddr: address(data.eTokens[i]),
                data: abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    _sourceAccount, _targetAccount, data.supplyAmts[i]
                )
            });
            k++;

            if (inputData.enterMarket[i]) {

                items[k] = IEulerExecute.EulerBatchItem({
                    allowError: false,
                    proxyAddr: address(markets),
                    data: abi.encodeWithSignature(
                        "enterMarket(uint256,address)",
                        targetId, data._supplyTokens[i]
                    )
                });
                k++;
            }
        }

        for(uint j = 0; j < helper.borrowlength; j++) {
            items[k] = IEulerExecute.EulerBatchItem({
                allowError: false,
                proxyAddr: address(data.dTokens[j]),
                data: abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    _sourceAccount, _targetAccount, data.borrowAmts[j]
                )
            });
            k++;
        }

        address[] memory deferLiquidityChecks = new address[](2);
        deferLiquidityChecks[0] = _sourceAccount;
        deferLiquidityChecks[1] = _targetAccount;

        eulerExec.batchDispatch(items, deferLiquidityChecks);

        _eventName = "LogEulerImport(address,uint,uint,address[],address[],bool[])";
		_eventParam = abi.encode(
			userAccount,
			sourceId,
			targetId,
			inputData.supplyTokens,
			inputData.borrowTokens,
			inputData.enterMarket
		);
    }
}

contract ConnectV2EulerImport is EulerImport {
	string public constant name = "Euler-import-v1.0";
}
