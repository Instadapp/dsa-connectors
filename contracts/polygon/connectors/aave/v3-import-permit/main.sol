//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
/**
 * @title Aave v3 import connector .
 * @dev  Import EOA's aave V3 position to DSA's aave v3 position
 */

import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import { AaveInterface, ATokenInterface } from "./interface.sol";
import "./helpers.sol";
import "./events.sol";

contract AaveV3ImportResolver is AaveHelpers {
	function _importAave(
		address userAccount,
		ImportInputData memory inputData,
		signedPermits memory permitData
	) internal returns (string memory _eventName, bytes memory _eventParam) {
		require(
			AccountInterface(address(this)).isAuth(userAccount),
			"user-account-not-auth"
		);

		require(inputData.supplyTokens.length > 0, "0-length-not-allowed");

		ImportData memory data;

		AaveInterface aave = AaveInterface(aaveProvider.getPool());

		data = getBorrowAmounts(userAccount, aave, inputData, data);
		data = getSupplyAmounts(userAccount, inputData, data);

		//  payback borrowed amount;
		_PaybackStable(
			data._borrowTokens.length,
			aave,
			data._borrowTokens,
			data.stableBorrowAmts,
			userAccount
		);
		_PaybackVariable(
			data._borrowTokens.length,
			aave,
			data._borrowTokens,
			data.variableBorrowAmts,
			userAccount
		);

		//permit this address to transfer aTokens
		_PermitATokens(
			userAccount,
			data.aTokens,
			data._supplyTokens,
			data.supplyAmts,
			permitData.v,
			permitData.r,
			permitData.s,
			permitData.expiry
		);

		//  transfer atokens to this address;
		_TransferAtokens(
			data._supplyTokens.length,
			aave,
			data.aTokens,
			data.supplyAmts,
			data._supplyTokens,
			userAccount
		);

		// borrow assets after migrating position
		if (data.convertStable) {
			_BorrowVariable(
				data._borrowTokens.length,
				aave,
				data._borrowTokens,
				data.totalBorrowAmtsWithFee
			);
		} else {
			_BorrowStable(
				data._borrowTokens.length,
				aave,
				data._borrowTokens,
				data.stableBorrowAmtsWithFee
			);
			_BorrowVariable(
				data._borrowTokens.length,
				aave,
				data._borrowTokens,
				data.variableBorrowAmtsWithFee
			);
		}

		_eventName = "LogAaveV3Import(address,bool,address[],address[],uint256[],uint256[],uint256[],uint256[])";
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

	/**
	 * @dev Import aave V3 position .
	 * @notice Import EOA's aave V3 position to DSA's aave v3 position
	 * @param userAccount The address of the EOA from which aave position will be imported
	 * @param inputData The struct containing all the neccessary input data
	 */
	function importAave(address userAccount, ImportInputData memory inputData, signedPermits memory permitData)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importAave(userAccount, inputData, permitData);
	}
}

contract ConnectV2AaveV3ImportPolygon is AaveV3ImportResolver {
	string public constant name = "Aave-v3-import-v1";
}
