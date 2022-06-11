//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title Refinance.
 * @dev Refinancing among Notional, Aave v2, Aave v3.
 */
import { AaveV2Interface, AaveV2DataProviderInterface, AaveV2LendingPoolProviderInterface, AaveV3Interface, AaveV3DataProviderInterface, AaveV3PoolProviderInterface } from "./interface.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { AaveV2Helpers } from "./helpers/aaveV2.sol";
import { AaveV3Helpers } from "./helpers/aaveV3.sol";
import { NotionalHelpers } from "./helpers/notional.sol";

contract RefinanceResolver is AaveV2Helpers, AaveV3Helpers, NotionalHelpers {
	struct RefinanceData {
		Protocol source;
		Protocol target;
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
		AaveV2Interface aaveV2;
		AaveV2DataProviderInterface aaveV2Data;
		AaveV3Interface aaveV3;
		AaveV3DataProviderInterface aaveV3Data;
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
		refinanceInternalData.aaveV2 = AaveV2Interface(
			AaveV2LendingPoolProviderInterface(getAaveV2Provider)
				.getLendingPool()
		);
		refinanceInternalData.aaveV2Data = aaveV2Data;
		refinanceInternalData.aaveV3 = AaveV3Interface(
			AaveV3PoolProviderInterface(getAaveV3Provider).getPool()
		);
		refinanceInternalData.aaveV3Data = aaveV3Data;

		refinanceInternalData.depositAmts;
		refinanceInternalData.paybackAmts;

		refinanceInternalData.tokens = getTokens(length, data.currencyIDs);
		refinanceInternalData.tokenInterfaces = getTokenInterfaces(
			length,
			refinanceInternalData.tokens
		);

		// Aave v2 to Notional
		if (
			data.source == Protocol.AaveV2 && data.target == Protocol.Notional
		) {
			NotionalBorrowData memory _notionalBorrowData;

			_notionalBorrowData.length = length;
			_notionalBorrowData.source = data.source;
			_notionalBorrowData.fee = data.debtFee;
			_notionalBorrowData.tokens = refinanceInternalData.tokens;
			_notionalBorrowData.redeemToUnderlying = data
				.redeemBorrowToUnderlying;
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
				refinanceInternalData.aaveV2,
				refinanceInternalData.tokenInterfaces,
				refinanceInternalData.paybackAmts,
				data.paybackRateModes
			);
			//withdraw aTokens from Aave-v2
			refinanceInternalData.depositAmts = _aaveV2Withdraw(
				refinanceInternalData.aaveV2,
				refinanceInternalData.aaveV2Data,
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
		}
		// Aave v3 to Notional
		else if (
			data.source == Protocol.AaveV3 && data.target == Protocol.Notional
		) {
			NotionalBorrowData memory _notionalBorrowData;

			_notionalBorrowData.length = length;
			_notionalBorrowData.source = data.source;
			_notionalBorrowData.fee = data.debtFee;
			_notionalBorrowData.tokens = refinanceInternalData.tokens;
			_notionalBorrowData.redeemToUnderlying = data
				.redeemBorrowToUnderlying;
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
			//payback debt on Aave-v3
			_aaveV3Payback(
				length,
				refinanceInternalData.aaveV3,
				refinanceInternalData.tokenInterfaces,
				refinanceInternalData.paybackAmts,
				data.paybackRateModes
			);
			//withdraw aTokens from Aave-v3
			refinanceInternalData.depositAmts = _aaveV3Withdraw(
				refinanceInternalData.aaveV3,
				refinanceInternalData.aaveV3Data,
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
		}

		_eventName = "LogRefinance(uint,uint,address[],uint[],uint[],uint[],uint[])";
		_eventParam = abi.encode(
			uint256(data.source),
			uint256(data.target),
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
