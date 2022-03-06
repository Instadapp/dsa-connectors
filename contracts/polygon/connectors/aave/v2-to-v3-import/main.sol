pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import "./interfaces.sol";
import "./helpers.sol";
import "./events.sol";

contract _AaveV2ToV3MigrationResolver is _AaveHelper {
	function _importAave(address userAccount, ImportInputData memory inputData)
		internal
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(
			AccountInterface(address(this)).isAuth(userAccount),
			"user-account-not-auth"
		);

		require(inputData.supplyTokens.length > 0, "0-length-not-allowed");

		ImportData memory data;

		AaveV2Interface aaveV2 = AaveV2Interface(
			aaveV2Provider.getLendingPool()
		);
		AaveV3Interface aaveV3 = AaveV3Interface(aaveV3Provider.getPool());

		data = getBorrowAmounts(userAccount, aaveV2, inputData, data);
		data = getSupplyAmounts(userAccount, inputData, data);

		//  payback borrowed amount;
		_PaybackStable(
			data._borrowTokens.length,
			aaveV2,
			data._borrowTokens,
			data.stableBorrowAmts,
			userAccount
		);
		_PaybackVariable(
			data._borrowTokens.length,
			aaveV2,
			data._borrowTokens,
			data.variableBorrowAmts,
			userAccount
		);

		//  transfer atokens to this address;
		_TransferAtokens(
			data._supplyTokens.length,
			aaveV2,
			data.aTokens,
			data.supplyAmts,
			data._supplyTokens,
			userAccount
		);

		// withdraw v2 supplied tokens
		_WithdrawTokensFromV2(
			data._supplyTokens.length,
			aaveV2,
			data.supplyAmts,
			data._supplyTokens
		);
		// deposit tokens in v3
		_depositTokensInV3(
			data._supplyTokens.length,
			aaveV3,
			data.supplyAmts,
			data._supplyTokens
		);

		// borrow assets in aave v3 after migrating position
		if (data.convertStable) {
			_BorrowVariable(
				data._borrowTokens.length,
				aaveV3,
				data._borrowTokens,
				data.totalBorrowAmtsWithFee
			);
		} else {
			_BorrowStable(
				data._borrowTokens.length,
				aaveV3,
				data._borrowTokens,
				data.stableBorrowAmtsWithFee
			);
			_BorrowVariable(
				data._borrowTokens.length,
				aaveV3,
				data._borrowTokens,
				data.variableBorrowAmtsWithFee
			);
		}

		_eventName = "LogAaveV2ImportToV3(address,bool,address[],address[],uint256,uint256[],uint256[],uint256[])";
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

	function importAaveV2ToV3(
		address userAccount,
		ImportInputData memory inputData
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importAave(userAccount, inputData);
	}

	function migrateAaveV2ToV3(ImportInputData memory inputData)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importAave(msg.sender, inputData);
	}
}

contract AaveV2ToV3MigrationResolverPolygon is _AaveV2ToV3MigrationResolver {
	string public constant name = "Aave-v2-to-v3-import";
}
