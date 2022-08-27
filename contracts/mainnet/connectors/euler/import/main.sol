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
	 * @param userAccount EOA address
	 * @param sourceId Sub-account id of "EOA" from which the funds will be transferred
	 * @param targetId Sub-account id of "DSA" to which the funds will be transferred
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
		require(sourceId < 256 && targetId < 256, "Id should be less than 256");

		(_eventName, _eventParam) = _importEuler(
			userAccount,
			sourceId,
			targetId,
			inputData
		);
	}

	/**
	 * @dev Import Euler position .
	 * @notice Import EOA's Euler position to DSA's Euler position
	 * @param userAccount EOA address
	 * @param sourceId Sub-account id of "EOA" from which the funds will be transferred
	 * @param targetId Sub-account id of "DSA" to which the funds will be transferred
	 * @param inputData The struct containing all the neccessary input data
	 */
	function _importEuler(
		address userAccount,
		uint256 sourceId,
		uint256 targetId,
		ImportInputData memory inputData
	) internal returns (string memory _eventName, bytes memory _eventParam) {
		require(inputData._supplyTokens.length > 0, "0-length-not-allowed");
		require(
			AccountInterface(address(this)).isAuth(userAccount),
			"user-account-not-auth"
		);
		require(
			inputData._enterMarket.length == inputData._supplyTokens.length,
			"lengths-not-same"
		);

		ImportData memory data;
		ImportHelper memory helper;

		helper.sourceAccount = getSubAccountAddress(userAccount, sourceId);
		helper.targetAccount = getSubAccountAddress(address(this), targetId);

		// BorrowAmts will be in underlying token decimals
		data = getBorrowAmounts(helper.sourceAccount, inputData, data);

		// SupplyAmts will be in 18 decimals
		data = getSupplyAmounts(helper.sourceAccount, inputData, data);

		helper.supplylength = data.supplyTokens.length;
		helper.borrowlength = data.borrowTokens.length;
		uint16 enterMarketsLength = 0;

		for (uint16 i = 0; i < inputData._enterMarket.length; i++) {
			if (inputData._enterMarket[i]) {
				++enterMarketsLength;
			}
		}

		helper.totalExecutions =
			helper.supplylength +
			enterMarketsLength +
			helper.borrowlength;

		IEulerExecute.EulerBatchItem[]
			memory items = new IEulerExecute.EulerBatchItem[](
				helper.totalExecutions
			);

		uint16 k = 0;

		for (uint16 i = 0; i < helper.supplylength; i++) {
			items[k++] = IEulerExecute.EulerBatchItem({
				allowError: false,
				proxyAddr: address(data.eTokens[i]),
				data: abi.encodeWithSignature(
					"transferFrom(address,address,uint256)",
					helper.sourceAccount,
					helper.targetAccount,
					data.supplyAmts[i]
				)
			});

			if (inputData._enterMarket[i]) {
				items[k++] = IEulerExecute.EulerBatchItem({
					allowError: false,
					proxyAddr: address(markets),
					data: abi.encodeWithSignature(
						"enterMarket(uint256,address)",
						targetId,
						data.supplyTokens[i]
					)
				});
			}
		}

		for (uint16 j = 0; j < helper.borrowlength; j++) {
			items[k++] = IEulerExecute.EulerBatchItem({
				allowError: false,
				proxyAddr: address(data.dTokens[j]),
				data: abi.encodeWithSignature(
					"transferFrom(address,address,uint256)",
					helper.sourceAccount,
					helper.targetAccount,
					data.borrowAmts[j]
				)
			});
		}

		address[] memory deferLiquidityChecks = new address[](2);
		deferLiquidityChecks[0] = helper.sourceAccount;
		deferLiquidityChecks[1] = helper.targetAccount;

		eulerExec.batchDispatch(items, deferLiquidityChecks);

		_eventName = "LogEulerImport(address,uint256,uint256,address[],uint256[],address[],uint256[],bool[])";
		_eventParam = abi.encode(
			userAccount,
			sourceId,
			targetId,
			inputData._supplyTokens,
			data.supplyAmts,
			inputData._borrowTokens,
			data.borrowAmts,
			inputData._enterMarket
		);
	}
}

contract ConnectV2EulerImport is EulerImport {
	string public constant name = "Euler-Import-v1.0";
}
