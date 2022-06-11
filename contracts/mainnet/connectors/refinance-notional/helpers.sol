//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

// import { Helpers } from "./helpers.sol";
import { Basic } from "../../common/basic.sol";
import { Token, NotionalInterface, BalanceAction, BalanceActionWithTrades, DepositActionType, AaveV2LendingPoolProviderInterface, AaveV2DataProviderInterface, AaveV2Interface, AaveV3PoolProviderInterface, AaveV3Interface, AaveV3DataProviderInterface } from "./interface.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Helpers is Basic {
	using SafeERC20 for IERC20;

	enum Protocol {
		AaveV2,
		AaveV3,
		Compound,
		Notional
	}

	uint256 internal constant LEND_TRADE = 0;
	uint256 internal constant BORROW_TRADE = 1;
	uint256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;
	uint256 internal constant ETH_CURRENCY_ID = 1;
	uint256 internal constant MAX_DEPOSIT = type(uint256).max;

	address payable constant feeCollector =
		0xb1DC62EC38E6E3857a887210C38418E4A17Da5B2;

	AaveV2DataProviderInterface internal constant aaveV2Data =
		AaveV2DataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

	NotionalInterface internal constant notional =
		NotionalInterface(0x1344A36A1B56144C3Bc62E7757377D288fDE0369);

	/**
	 * @dev get Aave Lending Pool Provider
	 */
	AaveV2LendingPoolProviderInterface internal constant getAaveV2Provider =
		AaveV2LendingPoolProviderInterface(
			0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
		);
	/**
	 * @dev Aave V3 Pool Provider
	 */
	AaveV3PoolProviderInterface internal constant getAaveV3Provider =
		AaveV3PoolProviderInterface(0xA55125A90d75a95EC00130E8E8C197dB5641Eb19); //rinkeby address

	/**
	 * @dev Aave V3 Pool Data Provider
	 */
	AaveV3DataProviderInterface internal constant aaveV3Data =
		AaveV3DataProviderInterface(0x256bBbeDbA70a1240a1EB64210abB1b063267408); //rinkeby address

	/**
	 * @dev get Referral Code
	 */
	uint16 internal constant getReferralCode = 3228;

	struct NotionalBorrowData {
		// refinance to Notional from source
		Protocol source;
		// length of tokens
		uint256 length;
		// debt fee
		uint256 fee;
		// borrow tokens
		address[] tokens;
		// true, then redeems the borrowed balance from cTokens to underlying token before transferring to account
		bool[] redeemToUnderlying;
		// borrow amts im underlying token denomination
		uint256[] amts;
		// aave V2 borrow rate modes
		uint256[] rateModes;
		// fCashAmount accounting for the borrowAmt with debtfee, calculated through SDK
		uint256[] fCashAmount;
		// borrow rate max, 0 means any is acceptable
		uint256[] maxBorrowRate;
		// notion defined currency IDs of borrowTokens
		uint256[] currencyIDs;
		// borrow markets based on the maturity where user wants to borrow
		uint256[] marketIndex;
	}

	// withdraw balance of Aave v2
	function getWithdrawBalanceV2(
		AaveV2DataProviderInterface aaveData,
		address token
	) internal view returns (uint256 bal) {
		(bal, , , , , , , , ) = aaveData.getUserReserveData(
			token,
			address(this)
		);
	}

	// withdraw balance of Aave v3
	function getWithdrawBalanceV3(
		AaveV3DataProviderInterface aaveData,
		address token
	) internal view returns (uint256 bal) {
		(bal, , , , , , , , ) = aaveData.getUserReserveData(
			token,
			address(this)
		);
	}

	function getAssetOrUnderlyingToken(uint16 currencyId, bool underlying)
		internal
		view
		returns (address)
	{
		// prettier-ignore
		(Token memory assetToken, Token memory underlyingToken) = notional.getCurrency(currencyId);
		return
			underlying ? underlyingToken.tokenAddress : assetToken.tokenAddress;
	}

	function toUint88(uint256 value) internal pure returns (uint88) {
		require(value <= type(uint88).max, "uint88 value overflow");
		return uint88(value);
	}

	function toUint32(uint256 value) internal pure returns (uint32) {
		require(value <= type(uint32).max, "uint32 value overflow");
		return uint32(value);
	}

	function toUint16(uint256 value) internal pure returns (uint16) {
		require(value <= type(uint16).max, "uint16 value overflow");
		return uint16(value);
	}

	function toUint8(uint256 value) internal pure returns (uint8) {
		require(value <= type(uint8).max, "uint8 value overflow");
		return uint8(value);
	}

	function getAaveV2PaybackAmt(uint256 rateMode, address token)
		internal
		returns (uint256 bal)
	{
		if (rateMode == 1) {
			(, bal, , , , , , , ) = aaveV2Data.getUserReserveData(
				token,
				address(this)
			);
		} else {
			(, , bal, , , , , , ) = aaveV2Data.getUserReserveData(
				token,
				address(this)
			);
		}
	}

	function getAaveV3PaybackAmt(uint256 rateMode, address token)
		internal
		returns (uint256 bal)
	{
		if (rateMode == 1) {
			(, bal, , , , , , , ) = aaveV3Data.getUserReserveData(
				token,
				address(this)
			);
		} else {
			(, , bal, , , , , , ) = aaveV3Data.getUserReserveData(
				token,
				address(this)
			);
		}
	}

	function calculateFee(
		uint256 amount,
		uint256 fee,
		bool toAdd
	) internal pure returns (uint256 feeAmount, uint256 _amount) {
		feeAmount = wmul(amount, fee);
		_amount = toAdd ? add(amount, feeAmount) : sub(amount, feeAmount);
	}

	function transferFees(address token, uint256 feeAmt) internal {
		if (feeAmt > 0) {
			if (token == ethAddr) {
				feeCollector.transfer(feeAmt);
			} else {
				IERC20(token).safeTransfer(feeCollector, feeAmt);
			}
		}
	}

	function calculateAndTransferFees(
		address token,
		uint256 amt,
		uint256 fee,
		bool toAdd
	) internal {
		token = (token == wethAddr) ? ethAddr : token;
		(uint256 feeAmt, uint256 _amt) = calculateFee(amt, fee, toAdd);
		transferFees(token, feeAmt);
	}

	function encodeBorrowTrade(
		uint256 marketIndex,
		uint256 fCashAmount,
		uint256 maxBorrowRate
	) internal pure returns (bytes32) {
		return
			(bytes32(BORROW_TRADE) << 248) |
			(bytes32(marketIndex) << 240) |
			(bytes32(fCashAmount) << 152) |
			(bytes32(maxBorrowRate) << 120);
	}

	function getTokens(uint256 length, uint256[] memory currencyIDs)
		internal
		view
		returns (address[] memory)
	{
		address[] memory tokens = new address[](length);
		for (uint256 i = 0; i < length; i++) {
			uint16 _currencyId = toUint16(currencyIDs[i]);
			if (_currencyId == ETH_CURRENCY_ID) {
				tokens[i] = wethAddr;
			} else {
				tokens[i] = getAssetOrUnderlyingToken(_currencyId, true);
			}
		}
		return tokens;
	}

	function getTokenInterfaces(uint256 length, address[] memory _tokens)
		internal
		pure
		returns (TokenInterface[] memory)
	{
		TokenInterface[] memory tokens = new TokenInterface[](length);
		for (uint256 i = 0; i < length; i++) {
			tokens[i] = TokenInterface(_tokens[i]);
		}
		return tokens;
	}
}
