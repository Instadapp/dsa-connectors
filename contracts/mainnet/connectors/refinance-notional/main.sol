//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title Refinance Notional, Aave v2.
 * @dev Refinancing.
 */
import { AaveV2Interface, AaveV2DataProviderInterface, AaveV2LendingPoolProviderInterface } from "./interface.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { AaveHelpers } from "./helpers/aaveV2.sol";
import { NotionalHelpers } from "./helpers/notional.sol";

contract RefinanceResolver is AaveHelpers, NotionalHelpers {
	struct RefinanceData {
		uint256 collateralFee;
		uint256 debtFee;
		uint256[] currencyIDs;
		uint256[] borrowMarketIndices;
		uint256[] borrowfCashAmts;
		uint256[] borrowAmts;
		uint256[] withdrawAmts;
		uint256[] paybackRateModes;
		uint256[] maxBorrowingRates;
		bool[] redeemBorrowToUnderlying;
		bool[] mintNTokens;
	}

	struct RefinanceInternalData {
		AaveV2Interface aave;
		AaveV2DataProviderInterface aaveData;
		uint256[] depositAmts;
		uint256[] paybackAmts;
		address[] tokens;
		TokenInterface[] tokenInterfaces;
	}

	function _refinance(RefinanceData calldata data)
		internal
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 length = data.currencyIDs.length;
		require(data.borrowMarketIndices.length == length, "length-mismatch");
		require(data.borrowfCashAmts.length == length, "length-mismatch");
		require(data.borrowAmts.length == length, "length-mismatch");
		require(data.withdrawAmts.length == length, "length-mismatch");
		require(data.paybackRateModes.length == length, "length-mismatch");
		require(data.maxBorrowingRates.length == length, "length-mismatch");
		require(
			data.redeemBorrowToUnderlying.length == length,
			"length-mismatch"
		);
		require(data.mintNTokens.length == length, "length-mismatch");

		RefinanceInternalData memory refinanceInternalData;
		refinanceInternalData.aave = AaveV2Interface(
			AaveV2LendingPoolProviderInterface(getAaveV2Provider)
				.getLendingPool()
		);
		refinanceInternalData.aaveData = aaveData;

		refinanceInternalData.depositAmts;
		refinanceInternalData.paybackAmts;

		refinanceInternalData.tokens = getTokens(length, data.currencyIDs);
		refinanceInternalData.tokenInterfaces = getTokenInterfaces(
			length,
			refinanceInternalData.tokens
		);

		// Aave v2 to Notional
		NotionalBorrowData memory _notionalBorrowData;

		_notionalBorrowData.length = length;
		_notionalBorrowData.fee = data.debtFee;
		_notionalBorrowData.tokens = refinanceInternalData.tokens;
		_notionalBorrowData.redeemToUnderlying = data.redeemBorrowToUnderlying;
		_notionalBorrowData.amts = data.borrowAmts;
		_notionalBorrowData.rateModes = data.paybackRateModes;
		_notionalBorrowData.fCashAmount = data.borrowfCashAmts;
		_notionalBorrowData.maxBorrowRate = data.maxBorrowingRates;
		_notionalBorrowData.currencyIDs = data.currencyIDs;
		_notionalBorrowData.marketIndex = data.borrowMarketIndices;

		//borrow on Notional
		refinanceInternalData.paybackAmts = _notionalBorrow(
			_notionalBorrowData
		);
		//payback debt on Aave-v2
		_aaveV2Payback(
			length,
			refinanceInternalData.aave,
			refinanceInternalData.tokenInterfaces,
			refinanceInternalData.paybackAmts,
			data.paybackRateModes
		);
		//withdraw aTokens from Aave-v2
		refinanceInternalData.depositAmts = _aaveV2Withdraw(
			refinanceInternalData.aave,
			refinanceInternalData.aaveData,
			length,
			refinanceInternalData.tokenInterfaces,
			data.withdrawAmts
		);
		//deposit on Notional
		_notionalDeposit(
			length,
			data.collateralFee,
			data.currencyIDs,
			refinanceInternalData.depositAmts,
			refinanceInternalData.tokens,
			data.mintNTokens
		);

		_eventName = "LogRefinance(uint,uint,address[],uint[],uint[],uint[],uint[])";
		_eventParam = abi.encode(
			data.collateralFee,
			data.debtFee,
			refinanceInternalData.tokens,
			refinanceInternalData.paybackAmts,
			refinanceInternalData.depositAmts,
			data.borrowMarketIndices,
			data.maxBorrowingRates
		);
	}

	/**
	 * @dev Refinance
	 * @notice Refinancing between Notional and Aave V2
	 * @param data refinance data.
	 */
	function refinance(RefinanceData calldata data)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _refinance(data);
	}
}

contract ConnectV2Refinance is RefinanceResolver {
	string public name = "Refinance-v1.2";
}
