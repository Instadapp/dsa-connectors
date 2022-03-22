//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Aave v2 to v3 import connector .
 * @dev  migrate aave V2 position to aave v3 position
 */

import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import "./interfaces.sol";
import "./helpers.sol";
import "./events.sol";

contract _AaveV2ToV3MigrationResolver is _AaveHelper {
	/**
	 * @dev Import aave position .
	 * @notice Import EOA's or DSA's aave V2 position to DSA's aave v3 position
	 * @param userAccount The address of the EOA from which aave position will be imported
	 * @param inputData The struct containing all the neccessary input data
	 * @param doImport boolean, to support DSA v2->v3 migration
	 */
	function _importAave(
		address userAccount,
		ImportInputData memory inputData,
		bool doImport
	) internal returns (string memory _eventName, bytes memory _eventParam) {
		if (doImport) {
			// check only when we are importing from user's address
			require(
				AccountInterface(address(this)).isAuth(userAccount),
				"user-account-not-auth"
			);
		}

		require(inputData.supplyTokens.length > 0, "0-length-not-allowed");

		ImportData memory data;

		AaveV2Interface aaveV2 = AaveV2Interface(
			aaveV2Provider.getLendingPool()
		);
		AaveV3Interface aaveV3 = AaveV3Interface(aaveV3Provider.getPool());

		data = getBorrowAmountsV2(userAccount, aaveV2, inputData, data);
		data = getSupplyAmountsV2(userAccount, inputData, data);

		//  payback borrowed amount;
		_PaybackStableV2(
			data._borrowTokens.length,
			aaveV2,
			data._borrowTokens,
			data.stableBorrowAmts,
			userAccount
		);
		_PaybackVariableV2(
			data._borrowTokens.length,
			aaveV2,
			data._borrowTokens,
			data.variableBorrowAmts,
			userAccount
		);

		if (doImport) {
			//  transfer atokens to user's DSA address;
			_TransferAtokensV2(
				data._supplyTokens.length,
				aaveV2,
				data.aTokens,
				data.supplyAmts,
				data._supplyTokens,
				userAccount
			);
		}

		// withdraw v2 supplied tokens
		_WithdrawTokensFromV2(
			data._supplyTokens.length,
			aaveV2,
			data.supplyAmts,
			data._supplyTokens
		);
		// deposit tokens in v3
		_depositTokensV3(
			data._supplyTokens.length,
			aaveV3,
			data.supplyAmts,
			data._supplyTokens
		);

		// borrow assets in aave v3 after migrating position
		if (data.convertStable) {
			_BorrowVariableV3(
				data._borrowTokens.length,
				aaveV3,
				data._borrowTokens,
				data.totalBorrowAmtsWithFee
			);
		} else {
			_BorrowStableV3(
				data._borrowTokens.length,
				aaveV3,
				data._borrowTokens,
				data.stableBorrowAmtsWithFee
			);
			_BorrowVariableV3(
				data._borrowTokens.length,
				aaveV3,
				data._borrowTokens,
				data.variableBorrowAmtsWithFee
			);
		}

		_eventName = "LogAaveImportV2ToV3(address,bool,bool,address[],address[],uint256[],uint256[],uint256[],uint256[])";
		_eventParam = abi.encode(
			userAccount,
			doImport,
			inputData.convertStable,
			inputData.supplyTokens,
			inputData.borrowTokens,
			inputData.flashLoanFees,
			data.supplyAmts,
			data.stableBorrowAmts,
			data.variableBorrowAmts
		);
	}

	/**
	 * @dev Import aave position .
	 * @notice Import EOA's aave V2 position to DSA's aave v3 position
	 * @param userAccount The address of the EOA from which aave position will be imported
	 * @param inputData The struct containing all the neccessary input data
	 */
	function importAaveV2ToV3(
		address userAccount,
		ImportInputData memory inputData
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importAave(userAccount, inputData, true);
	}

	/**
	 * @dev Migrate aave position .
	 * @notice Migrate DSA's aave V2 position to DSA's aave v3 position
	 * @param inputData The struct containing all the neccessary input data
	 */
	function migrateAaveV2ToV3(ImportInputData memory inputData)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importAave(
			address(this),
			inputData,
			false
		);
	}
}

contract ConnectV2AaveV2ToV3MigrationPolygon is _AaveV2ToV3MigrationResolver {
	string public constant name = "Aave-Import-v2-to-v3";
}
