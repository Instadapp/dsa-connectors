//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
/**
 * @title Spark import connector .
 * @dev  Import EOA's spark position to DSA's spark position
 */
import { TokenInterface, AccountInterface } from "../../common/interfaces.sol";
import { SparkInterface, STokenInterface } from "./interface.sol";
import "./helpers.sol";
import "./events.sol";

contract SparkImportResolver is SparkHelpers {
	function _importSpark(address userAccount, ImportInputData memory inputData)
		internal
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(
			AccountInterface(address(this)).isAuth(userAccount),
			"user-account-not-auth"
		);

		require(inputData.supplyTokens.length > 0, "0-length-not-allowed");

		ImportData memory data;

		SparkInterface spark = SparkInterface(sparkProvider.getPool());

		data = getBorrowAmounts(userAccount, spark, inputData, data);
		data = getSupplyAmounts(userAccount, inputData, data);

		//  payback borrowed amount;
		_PaybackStable(
			data._borrowTokens.length,
			spark,
			data._borrowTokens,
			data.stableBorrowAmts,
			userAccount
		);
		_PaybackVariable(
			data._borrowTokens.length,
			spark,
			data._borrowTokens,
			data.variableBorrowAmts,
			userAccount
		);

		//  transfer sTokens to this address;
		_TransferStokens(
			data._supplyTokens.length,
			spark,
			data.sTokens,
			data.supplyAmts,
			data._supplyTokens,
			userAccount
		);

		// borrow assets after migrating position
		if (data.convertStable) {
			_BorrowVariable(
				data._borrowTokens.length,
				spark,
				data._borrowTokens,
				data.totalBorrowAmtsWithFee
			);
		} else {
			_BorrowStable(
				data._borrowTokens.length,
				spark,
				data._borrowTokens,
				data.stableBorrowAmtsWithFee
			);
			_BorrowVariable(
				data._borrowTokens.length,
				spark,
				data._borrowTokens,
				data.variableBorrowAmtsWithFee
			);
		}

		_eventName = "LogSparkImport(address,bool,address[],address[],uint256[],uint256[],uint256[],uint256[])";
		_eventParam = abi.encode(
			userAccount,
			inputData.convertStable,
			inputData.supplyTokens,
			inputData.borrowTokens,
			inputData.flashLoanFees,
			data.supplyAmts,
			data.stableBorrowAmts,
			data.variableBorrowAmts
		);
	}

	function _importSparkWithCollateral(address userAccount, ImportInputData memory inputData, bool[] memory enableCollateral)
		internal
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(
			AccountInterface(address(this)).isAuth(userAccount),
			"user-account-not-auth"
		);

		require(inputData.supplyTokens.length > 0, "0-length-not-allowed");
		require(enableCollateral.length == inputData.supplyTokens.length, "lengths-not-same");

		ImportData memory data;

		SparkInterface spark = SparkInterface(sparkProvider.getPool());

		data = getBorrowAmounts(userAccount, spark, inputData, data);
		data = getSupplyAmounts(userAccount, inputData, data);

		//  payback borrowed amount;
		_PaybackStable(
			data._borrowTokens.length,
			spark,
			data._borrowTokens,
			data.stableBorrowAmts,
			userAccount
		);
		_PaybackVariable(
			data._borrowTokens.length,
			spark,
			data._borrowTokens,
			data.variableBorrowAmts,
			userAccount
		);

		//  transfer sTokens to this address;
		_TransferStokensWithCollateral(
			data._supplyTokens.length,
			spark,
			data.sTokens,
			data.supplyAmts,
			data._supplyTokens,
			enableCollateral,
			userAccount
		);

		// borrow assets after migrating position
		if (data.convertStable) {
			_BorrowVariable(
				data._borrowTokens.length,
				spark,
				data._borrowTokens,
				data.totalBorrowAmtsWithFee
			);
		} else {
			_BorrowStable(
				data._borrowTokens.length,
				spark,
				data._borrowTokens,
				data.stableBorrowAmtsWithFee
			);
			_BorrowVariable(
				data._borrowTokens.length,
				spark,
				data._borrowTokens,
				data.variableBorrowAmtsWithFee
			);
		}

		_eventName = "LogSparkImportWithCollateral(address,bool,address[],address[],uint256[],uint256[],uint256[],uint256[],bool[])";
		_eventParam = abi.encode(
			userAccount,
			inputData.convertStable,
			inputData.supplyTokens,
			inputData.borrowTokens,
			inputData.flashLoanFees,
			data.supplyAmts,
			data.stableBorrowAmts,
			data.variableBorrowAmts,
			enableCollateral
		);
	}

	/**
	 * @dev Import spark position .
	 * @notice Import EOA's spark position to DSA's spark position
	 * @param userAccount The address of the EOA from which spark position will be imported
	 * @param inputData The struct containing all the neccessary input data
	 */
	function importSpark(address userAccount, ImportInputData memory inputData)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importSpark(userAccount, inputData);
	}

	/**
	 * @dev Import spark position (with collateral).
	 * @notice Import EOA's spark position to DSA's spark position
	 * @param userAccount The address of the EOA from which spark position will be imported
	 * @param inputData The struct containing all the neccessary input data
	 * @param enableCollateral The boolean array to enable selected collaterals in the imported position
	 */
	function importSparkWithCollateral(address userAccount, ImportInputData memory inputData, bool[] memory enableCollateral)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importSparkWithCollateral(userAccount, inputData, enableCollateral);
	}
}

contract ConnectV2SparkImport is SparkImportResolver {
	string public constant name = "Spark-import-v1.1";
}
