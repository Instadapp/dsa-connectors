// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title Morpho-Compound-Import.
 * @dev Lending & Borrowing.
 */

import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import { MorphoCompoundHelper } from "./helpers.sol";
import { Events } from "./events.sol";

contract MorphoCompoundImportResolver is MorphoCompoundHelper {
	function _importMorphoCompound(
        address userAccount_
		ImportInputData memory importInputData_
	) internal returns (string memory eventName_, bytes memory eventParam_) {
		require(
			AccountInterface(address(this)).isAuth(
				userAccount_
			),
			"user-account-not-auth"
		);

		require(importInputData_.supplyCTokens.length > 0, "0-length-not-allowed");

		ImportData memory data;

		// get info about all borrowings and lendings by the user on Morpho-Compound
		data = getBorrowAmounts(importInputData_, data);
		data = getSupplyAmounts(importInputData_, data);

		// pay back user's debt using flash loan funds
		_paybackDebt(
			importInputData_.userAccount,
			data.borrowCtokensAddr,
			data.borrowAmts
		);

		// transfer user's tokens to DSA
		_transferCTokensToDsa(
			importInputData_.userAccount,
			data.supplyCtokens,
			data.supplyAmts
		);

		// borrow the earlier position from Compound with flash loan fee added
		_borrowDebtPosition(
			data.borrowCtokensAddr,
			data.borrowAmts,
			importInputData_.flashLoanFees
		);

		_eventName = "LogMorphoCompoundImport(address,address[],address[],uint256[],uint256[])";
		_eventParam = abi.encode(
			importInputData_.userAccount,
			importInputData_.supplyCTokens,
			importInputData_.borrowCTokens,
			data.supplyAmts,
			data.borrowAmts
		);
	}

	/**
	 * @notice import Morpho-Compound position of the address passed in as userAccount
	 * @dev Import EOA's morpho-compound position to DSA's morpho-compound position
	 * @param userAccount The address of the EOA from which aave position will be imported
	 * @param inputData The struct containing all the neccessary input data
	 */
	function importMorphoCompound(
		address userAccount_,
		ImportInputData memory inputData_
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		(_eventName, _eventParam) = _importMorphoCompound(
			userAccount_,
			inputData_
		);
	}
}

contract ConnectV2MorphoCompoundImport is MorphoCompoundImportResolver {
	string public constant name = "Morpho-Compound-Import-v2";
}
