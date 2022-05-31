// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Notional
 * @dev Fixed Rate Lending and Borrowing
 */

import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { DepositActionType, BalanceActionWithTrades, BalanceAction } from "./interface.sol";
import { TokenInterface } from "../../common/interfaces.sol";

abstract contract NotionalResolver is Events, Helpers {
	/**
	 * @notice Deposit collateral into Notional, this should only be used for reducing risk of
	 * liquidation.
	 *  @dev Deposits into Notional are not earning fixed rates, they are earning the cToken
	 * lending rate. In order to lend at fixed rates use `depositAndLend`
	 * @param currencyId notional defined currency id to deposit
	 * @param useUnderlying if true, will accept a deposit in the underlying currency (i.e DAI), if false
	 * will use the asset currency (i.e. cDAI)
	 * @param depositAmount amount of tokens to deposit
	 * @param getId id of depositAmount
	 * @param setId id to set the value of notional cash deposit increase (denominated in asset cash, i.e. cDAI)
	 */
	function depositCollateral(
		uint16 currencyId,
		bool useUnderlying,
		uint256 depositAmount,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		depositAmount = getDepositAmountAndSetApproval(
			getId,
			currencyId,
			useUnderlying,
			depositAmount
		);

		uint256 assetCashDeposited;
		if (useUnderlying && currencyId == ETH_CURRENCY_ID) {
			assetCashDeposited = notional.depositUnderlyingToken{
				value: depositAmount
			}(address(this), currencyId, depositAmount);
		} else if (useUnderlying) {
			assetCashDeposited = notional.depositUnderlyingToken(
				address(this),
				currencyId,
				depositAmount
			);
		} else {
			assetCashDeposited = notional.depositAssetToken(
				address(this),
				currencyId,
				depositAmount
			);
		}

		setUint(setId, assetCashDeposited);

		_eventName = "LogDepositCollateral(address,uint16,bool,uint256,uint256)";
		_eventParam = abi.encode(
			address(this),
			currencyId,
			useUnderlying,
			depositAmount,
			assetCashDeposited
		);
	}

	/**
	 * @notice Withdraw collateral from Notional
	 * @dev This spell allows users to withdraw collateral from Notional
	 * @param currencyId notional defined currency id to withdraw
	 * @param redeemToUnderlying if true, will redeem the amount withdrawn to the underlying currency (i.e. DAI),
	 * if false, will simply withdraw the asset token (i.e. cDAI)
	 * @param withdrawAmount amount of tokens to withdraw, denominated in asset tokens (i.e. cDAI)
	 * @param getId id of withdraw amount
	 * @param setId id to set the value of amount withdrawn, if redeemToUnderlying this amount will be in underlying
	 * (i.e. DAI), if not redeemToUnderlying this amount will be asset tokens (i.e. cDAI)
	 */
	function withdrawCollateral(
		uint16 currencyId,
		bool redeemToUnderlying,
		uint256 withdrawAmount,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		withdrawAmount = getUint(getId, withdrawAmount);
		uint88 amountInternalPrecision = withdrawAmount == type(uint256).max
			? toUint88(getCashOrNTokenBalance(currencyId, false))
			: toUint88(convertToInternal(currencyId, withdrawAmount));

		uint256 amountWithdrawn = notional.withdraw(
			currencyId,
			amountInternalPrecision,
			redeemToUnderlying
		);
		// Sets the amount of tokens withdrawn to address(this), Notional returns this value
		// in the native precision of the token that was withdrawn
		setUint(setId, amountWithdrawn);

		_eventName = "LogWithdrawCollateral(address,uint16,bool,uint256)";
		_eventParam = abi.encode(
			address(this),
			currencyId,
			redeemToUnderlying,
			amountWithdrawn
		);
	}

	/**
	 * @notice Claims NOTE tokens and transfers to the address
	 * @dev This spell allows users to claim nToken incentives
	 * @param setId the id to set the balance of NOTE tokens claimed
	 */
	function claimNOTE(uint256 setId)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 notesClaimed = notional.nTokenClaimIncentives();
		setUint(setId, notesClaimed);

		_eventName = "LogClaimNOTE(address,uint256)";
		_eventParam = abi.encode(address(this), notesClaimed);
	}

	/**
	 * @notice Redeem nTokens allowing for accepting of fCash residuals
	 * @dev This spell allows users to redeem nTokens even when there are fCash residuals that
	 * cannot be sold when markets are at extremely high utilization
	 * @param currencyId notional defined currency id of nToken
	 * @param sellTokenAssets set to false to accept fCash residuals into portfolio, set to true will
	 * sell fCash residuals back to cash
	 * @param tokensToRedeem amount of nTokens to redeem
	 * @param getId id of amount of tokens to redeem
	 * @param setId id to set amount of asset cash from redeem
	 */
	function redeemNTokenRaw(
		uint16 currencyId,
		bool sellTokenAssets,
		uint96 tokensToRedeem,
		bool acceptResidualAssets,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		tokensToRedeem = getNTokenRedeemAmount(
			currencyId,
			tokensToRedeem,
			getId
		);

		int256 _assetCashChange = notional.nTokenRedeem(
			address(this),
			currencyId,
			tokensToRedeem,
			sellTokenAssets,
			acceptResidualAssets
		);

		// Floor asset cash change at zero in order to properly set the uint. If the asset cash change is negative
		// (this will almost certainly never happen), then no withdraw is possible.
		uint256 assetCashChange = _assetCashChange > 0
			? uint256(_assetCashChange)
			: 0;

		setUint(setId, assetCashChange);

		_eventName = "LogRedeemNTokenRaw(address,uint16,bool,uint96,int256)";
		_eventParam = abi.encode(
			address(this),
			currencyId,
			sellTokenAssets,
			tokensToRedeem,
			assetCashChange
		);
	}

	/**
	 * @notice Redeems nTokens to cash and withdraws the resulting cash
	 * @dev Also possible to use redeemNTokenRaw and withdrawCollateral to achieve the same
	 * result but this is more gas efficient, it does it in one call to Notional
	 * @param currencyId notional defined currency id of nToken
	 * @param tokensToRedeem amount of nTokens to redeem
	 * @param amountToWithdraw amount of asset cash to withdraw, if set to uint(-1) then will withdraw the
	 * entire cash balance in notional
	 * @param redeemToUnderlying if true, will redeem the asset cash withdrawn to underlying tokens
	 * @param getId id of amount of tokens to redeem
	 * @param setId id to set amount of asset cash or underlying tokens withdrawn
	 */
	function redeemNTokenAndWithdraw(
		uint16 currencyId,
		uint96 tokensToRedeem,
		uint256 amountToWithdraw,
		bool redeemToUnderlying,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		tokensToRedeem = getNTokenRedeemAmount(
			currencyId,
			tokensToRedeem,
			getId
		);

		BalanceAction[] memory action = new BalanceAction[](1);
		action[0].actionType = DepositActionType.RedeemNToken;
		action[0].currencyId = currencyId;
		action[0].depositActionAmount = tokensToRedeem;
		action[0].redeemToUnderlying = redeemToUnderlying;
		if (amountToWithdraw == type(uint256).max) {
			// This setting will override the withdrawAmountInternalPrecision
			action[0].withdrawEntireCashBalance = true;
		} else {
			action[0].withdrawAmountInternalPrecision = amountToWithdraw;
		}

		executeActionWithBalanceChange(
			action,
			0,
			currencyId,
			redeemToUnderlying,
			setId
		);

		_eventName = "LogRedeemNTokenWithdraw(address,uint16,uint96,uint256,bool)";
		_eventParam = abi.encode(
			address(this),
			currencyId,
			tokensToRedeem,
			amountToWithdraw,
			redeemToUnderlying
		);
	}

	/**
	 * @notice Redeems nTokens and uses the cash to repay a borrow.
	 * @dev When specifying fCashAmount be sure to calculate it such that the account
	 * has enough cash after redeeming nTokens to pay down the debt. This can be done
	 * off-chain using the Notional SDK.
	 * @param currencyId notional defined currency id of nToken
	 * @param tokensToRedeem amount of nTokens to redeem
	 * @param marketIndex the market index that references where the account will lend
	 * @param fCashAmount amount of fCash to lend into the market (this has the effect or repaying
	 * the borrowed cash at current market rates), the corresponding amount of cash will be taken
	 * from the account after redeeming nTokens.
	 * @param minLendRate minimum rate where the user will lend, if the rate is lower will revert
	 * @param getId id of amount of tokens to redeem
	 */
	function redeemNTokenAndDeleverage(
		uint16 currencyId,
		uint96 tokensToRedeem,
		uint8 marketIndex,
		uint88 fCashAmount,
		uint32 minLendRate,
		uint256 getId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		tokensToRedeem = getNTokenRedeemAmount(
			currencyId,
			tokensToRedeem,
			getId
		);

		BalanceActionWithTrades[] memory action = new BalanceActionWithTrades[](
			1
		);
		action[0].actionType = DepositActionType.RedeemNToken;
		action[0].currencyId = currencyId;
		action[0].depositActionAmount = tokensToRedeem;
		// Withdraw amount, withdraw cash balance and redeemToUnderlying are all 0 or false

		bytes32[] memory trades = new bytes32[](1);
		trades[0] = encodeLendTrade(marketIndex, fCashAmount, minLendRate);
		action[0].trades = trades;

		notional.batchBalanceAndTradeAction(address(this), action);

		_eventName = "LogRedeemNTokenAndDeleverage(address,uint16,uint96,uint8,uint88)";
		_eventParam = abi.encode(
			address(this),
			currencyId,
			tokensToRedeem,
			marketIndex,
			fCashAmount
		);
	}

	/**
	 * @notice Deposit asset or underlying tokens and mint nTokens in a single transaction
	 * @dev This spell allows users to deposit and mint nTokens (providing liquidity)
	 * @param currencyId notional defined currency id to deposit
	 * @param depositAmount amount of tokens to deposit
	 * @param useUnderlying if true, will accept a deposit in the underlying currency (i.e DAI), if false
	 * will use the asset currency (i.e. cDAI)
	 * @param getId id of depositAmount
	 * @param setId id to set the value of nToken balance change
	 */
	function depositAndMintNToken(
		uint16 currencyId,
		uint256 depositAmount,
		bool useUnderlying,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		depositAmount = getDepositAmountAndSetApproval(
			getId,
			currencyId,
			useUnderlying,
			depositAmount
		);

		BalanceAction[] memory action = new BalanceAction[](1);
		action[0].actionType = useUnderlying
			? DepositActionType.DepositUnderlyingAndMintNToken
			: DepositActionType.DepositAssetAndMintNToken;
		action[0].currencyId = currencyId;
		action[0].depositActionAmount = depositAmount;
		// withdraw amount, withdraw cash and redeem to underlying are all 0 and false

		uint256 nTokenBefore = getCashOrNTokenBalance(currencyId, true);
		uint256 msgValue = getMsgValue(
			currencyId,
			useUnderlying,
			depositAmount
		);

		notional.batchBalanceAction{ value: msgValue }(address(this), action);

		uint256 nTokenBalanceChange = sub(
			getCashOrNTokenBalance(currencyId, true),
			nTokenBefore
		);

		if (setId != 0) {
			// Set the amount of nTokens minted
			setUint(setId, uint256(nTokenBalanceChange));
		}

		_eventName = "LogDepositAndMintNToken(address,uint16,bool,uint256,int256)";
		_eventParam = abi.encode(
			address(this),
			currencyId,
			useUnderlying,
			depositAmount,
			nTokenBalanceChange
		);
	}

	/**
	 * @notice Uses existing Notional cash balance (deposits in Notional held as cTokens) and uses them to mint
	 * nTokens.
	 * @dev This spell allows users to mint nTokens (providing liquidity) from existing cash balance.
	 * @param currencyId notional defined currency id of the cash balance
	 * @param cashBalanceToMint amount of account's cash balance to convert to nTokens
	 * @param getId id of cash balance
	 * @param setId id to set the value of nToken increase
	 */
	function mintNTokenFromCash(
		uint16 currencyId,
		uint256 cashBalanceToMint,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		cashBalanceToMint = getUint(getId, cashBalanceToMint);
		if (cashBalanceToMint == type(uint256).max)
			cashBalanceToMint = getCashOrNTokenBalance(currencyId, false);

		BalanceAction[] memory action = new BalanceAction[](1);
		action[0].actionType = DepositActionType.ConvertCashToNToken;
		action[0].currencyId = currencyId;
		action[0].depositActionAmount = cashBalanceToMint;
		// NOTE: withdraw amount, withdraw cash and redeem to underlying are all 0 and false

		uint256 nTokenBefore = getCashOrNTokenBalance(currencyId, true);

		notional.batchBalanceAction(address(this), action);

		uint256 nTokenBalanceChange = sub(
			getCashOrNTokenBalance(currencyId, true),
			nTokenBefore
		);

		if (setId != 0) {
			// Set the amount of nTokens minted
			setUint(setId, uint256(nTokenBalanceChange));
		}

		_eventName = "LogMintNTokenFromCash(address,uint16,uint256,int256)";
		_eventParam = abi.encode(
			address(this),
			currencyId,
			cashBalanceToMint,
			nTokenBalanceChange
		);
	}

	/**
	 * @notice Deposits some amount of tokens and lends them in the specified market. This method can also be used to repay a
	 * borrow early by specifying the corresponding market index of an existing borrow.
	 * @dev Setting the fCash amount and minLendRate are best calculated using the Notional SDK off chain. They can
	 * be calculated on chain but there is a significant gas cost to doing so. If there is insufficient depositAmount for the
	 * fCashAmount specified Notional will revert. In most cases there will be some dust amount of cash left after lending and
	 * this method will withdraw that dust back to the account.
	 * @param currencyId notional defined currency id to lend
	 * @param depositAmount amount of cash to deposit to lend
	 * @param useUnderlying if true, will accept a deposit in the underlying currency (i.e DAI), if false
	 * will use the asset currency (i.e. cDAI)
	 * @param marketIndex the market index to lend to. This is a number from 1 to 7 which corresponds to the tenor
	 * of the fCash asset to lend. Tenors are described here: https://docs.notional.finance/notional-v2/quarterly-rolls/tenors
	 * @param fCashAmount amount of fCash for the account to receive, this is equal to how much the account will receive
	 * at maturity (principal plus interest).
	 * @param minLendRate the minimum interest rate that the account is willing to lend at, if set to zero the account will accept
	 * any lending rate
	 * @param getId returns the deposit amount
	 */
	function depositAndLend(
		uint16 currencyId,
		uint256 depositAmount,
		bool useUnderlying,
		uint8 marketIndex,
		uint88 fCashAmount,
		uint32 minLendRate,
		uint256 getId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		depositAmount = getDepositAmountAndSetApproval(
			getId,
			currencyId,
			useUnderlying,
			depositAmount
		);

		BalanceActionWithTrades[] memory action = new BalanceActionWithTrades[](
			1
		);
		action[0].actionType = useUnderlying
			? DepositActionType.DepositUnderlying
			: DepositActionType.DepositAsset;
		action[0].currencyId = currencyId;
		action[0].depositActionAmount = depositAmount;
		// Withdraw any residual cash from lending back to the token that was used
		action[0].withdrawEntireCashBalance = true;
		action[0].redeemToUnderlying = useUnderlying;

		bytes32[] memory trades = new bytes32[](1);
		trades[0] = encodeLendTrade(marketIndex, fCashAmount, minLendRate);
		action[0].trades = trades;

		uint256 msgValue = getMsgValue(
			currencyId,
			useUnderlying,
			depositAmount
		);
		notional.batchBalanceAndTradeAction{ value: msgValue }(
			address(this),
			action
		);

		_eventName = "LogDepositAndLend(address,uint16,bool,uint256,uint8,uint88,uint32)";
		_eventParam = abi.encode(
			address(this),
			currencyId,
			useUnderlying,
			depositAmount,
			marketIndex,
			fCashAmount,
			minLendRate
		);
	}

	/**
	 * @notice Deposits some amount of tokens as collateral and borrows. This can be achieved by combining multiple spells but this
	 * method is more gas efficient by only making a single call to Notional.
	 * @dev Setting the fCash amount and maxBorrowRate are best calculated using the Notional SDK off chain. The amount of fCash
	 * when borrowing is more forgiving compared to lending since generally accounts will over collateralize and dust amounts are
	 * less likely to cause reverts. The Notional SDK will also provide calculations to tell the user what their LTV is for a given
	 * borrowing action.
	 * @param depositCurrencyId notional defined currency id of the collateral to deposit
	 * @param depositAction one of the following values which will define how the collateral is deposited:
	 *  - None: no collateral will be deposited
	 *  - DepositAsset: deposit amount will be specified in asset tokens (i.e. cTokens)
	 *  - DepositUnderlying: deposit amount will be specified in underlying tokens (i.e. DAI)
	 *  - DepositAssetAndMintNToken: deposit amount will be converted to nTokens
	 *  - DepositUnderlyingAndMintNToken: deposit amount will be converted to nTokens
	 *
	 *  Technically these two deposit types can be used, but there is not a clear reason why they would be used in combination
	 *  with borrowing:
	 *  - RedeemNToken
	 *  - ConvertCashToNToken
	 *
	 * @param depositAmount amount of cash to deposit as collateral
	 * @param borrowCurrencyId id of the currency to borrow
	 * @param marketIndex the market index to borrow from. This is a number from 1 to 7 which corresponds to the tenor
	 * of the fCash asset to borrow. Tenors are described here: https://docs.notional.finance/notional-v2/quarterly-rolls/tenors
	 * @param fCashAmount amount of fCash for the account to borrow, this is equal to how much the account must pay
	 * at maturity (principal plus interest).
	 * @param maxBorrowRate the maximum interest rate that the account is willing to borrow at, if set to zero the account will accept
	 * any borrowing rate
	 * @param redeemToUnderlying if true, redeems the borrowed balance from cTokens down to the underlying token before transferring
	 * to the account
	 * @param getId returns the collateral deposit amount
	 * @param setId sets the amount that the account borrowed (i.e. how much of borrowCurrencyId it has received)
	 */
	function depositCollateralBorrowAndWithdraw(
		uint16 depositCurrencyId,
		DepositActionType depositAction,
		uint256 depositAmount,
		uint16 borrowCurrencyId,
		uint8 marketIndex,
		uint88 fCashAmount,
		uint32 maxBorrowRate,
		bool redeemToUnderlying,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		bool useUnderlying = (depositAction ==
			DepositActionType.DepositUnderlying ||
			depositAction == DepositActionType.DepositUnderlyingAndMintNToken);

		depositAmount = getDepositAmountAndSetApproval(
			getId,
			depositCurrencyId,
			useUnderlying,
			depositAmount
		);

		BalanceActionWithTrades[]
			memory actions = getDepositCollateralBorrowAndWithdrawActions(
				depositCurrencyId,
				depositAction,
				depositAmount,
				borrowCurrencyId,
				marketIndex,
				fCashAmount,
				maxBorrowRate,
				redeemToUnderlying
			);

		uint256 msgValue = getMsgValue(
			depositCurrencyId,
			useUnderlying,
			depositAmount
		);
		executeTradeActionWithBalanceChange(
			actions,
			msgValue,
			borrowCurrencyId,
			redeemToUnderlying,
			setId
		);

		_eventName = "LogDepositCollateralBorrowAndWithdraw(address,bool,uint256,uint16,uint8,uint88,uint32,bool)";
		_eventParam = abi.encode(
			address(this),
			useUnderlying,
			depositAmount,
			borrowCurrencyId,
			marketIndex,
			fCashAmount,
			maxBorrowRate,
			redeemToUnderlying
		);
	}

	/**
	 * @notice Allows an account to withdraw from a fixed rate lend by selling the fCash back to the market. Equivalent to
	 * borrowing from the Notional perspective.
	 * @dev Setting the fCash amount and maxBorrowRate are best calculated using the Notional SDK off chain. Similar to borrowing,
	 * setting these amounts are a bit more forgiving since there is no change of reverts due to dust amounts.
	 * @param currencyId notional defined currency id of the lend asset to withdraw
	 * @param marketIndex the market index of the fCash asset. This is a number from 1 to 7 which corresponds to the tenor
	 * of the fCash asset. Tenors are described here: https://docs.notional.finance/notional-v2/quarterly-rolls/tenors
	 * @param fCashAmount amount of fCash at the marketIndex that should be sold
	 * @param maxBorrowRate the maximum interest rate that the account is willing to sell fCash at at, if set to zero the
	 * account will accept any rate
	 * @param setId sets the amount that the account has received when withdrawing its lend
	 */
	function withdrawLend(
		uint16 currencyId,
		uint8 marketIndex,
		uint88 fCashAmount,
		uint32 maxBorrowRate,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		bool useUnderlying = currencyId != ETH_CURRENCY_ID;
		BalanceActionWithTrades[] memory action = new BalanceActionWithTrades[](
			1
		);
		action[0].actionType = DepositActionType.None;
		action[0].currencyId = currencyId;
		// Withdraw borrowed amount to wallet
		action[0].withdrawEntireCashBalance = true;
		action[0].redeemToUnderlying = useUnderlying;

		bytes32[] memory trades = new bytes32[](1);
		trades[0] = encodeBorrowTrade(marketIndex, fCashAmount, maxBorrowRate);
		action[0].trades = trades;

		executeTradeActionWithBalanceChange(
			action,
			0,
			currencyId,
			useUnderlying,
			setId
		);

		_eventName = "LogWithdrawLend(address,uint16,uint8,uint88,uint32)";
		_eventParam = abi.encode(
			address(this),
			currencyId,
			marketIndex,
			fCashAmount,
			maxBorrowRate
		);
	}

	/// @notice Mints sNOTE from the underlying BPT token.
	/// @dev Mints sNOTE from the underlying BPT token.
	/// @param bptAmount is the amount of BPT to transfer from the msg.sender.
	function mintSNoteFromBPT(uint256 bptAmount)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		if (bptAmount == type(uint256).max)
			bptAmount = bpt.balanceOf(address(this));

		approve(bpt, address(staking), bptAmount);

		staking.mintFromBPT(bptAmount);

		_eventName = "LogMintSNoteFromBPT(address,uint256)";
		_eventParam = abi.encode(address(this), bptAmount);
	}

	/// @notice Mints sNOTE from some amount of NOTE and ETH
	/// @dev Mints sNOTE from some amount of NOTE and ETH
	/// @param noteAmount amount of NOTE to transfer into the sNOTE contract
	/// @param minBPT slippage parameter to prevent front running
	function mintSNoteFromETH(
		uint256 noteAmount,
		uint256 ethAmount,
		uint256 minBPT,
		uint256 getId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		noteAmount = getUint(getId, noteAmount);
		if (noteAmount == type(uint256).max)
			noteAmount = note.balanceOf(address(this));

		if (ethAmount == type(uint256).max) ethAmount = address(this).balance;

		approve(note, address(staking), noteAmount);

		staking.mintFromETH{ value: ethAmount }(noteAmount, minBPT);

		_eventName = "LogMintSNoteFromETH(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(address(this), ethAmount, noteAmount, minBPT);
	}

	/// @notice Mints sNOTE from some amount of NOTE and WETH
	/// @dev Mints sNOTE from some amount of NOTE and WETH
	/// @param noteAmount amount of NOTE to transfer into the sNOTE contract
	/// @param wethAmount amount of WETH to transfer into the sNOTE contract
	/// @param minBPT slippage parameter to prevent front running
	function mintSNoteFromWETH(
		uint256 noteAmount,
		uint256 wethAmount,
		uint256 minBPT,
		uint256 getId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		noteAmount = getUint(getId, noteAmount);
		if (noteAmount == type(uint256).max)
			noteAmount = note.balanceOf(address(this));

		if (wethAmount == type(uint256).max)
			wethAmount = weth.balanceOf(address(this));

		approve(note, address(staking), noteAmount);
		approve(weth, address(staking), wethAmount);

		staking.mintFromWETH(noteAmount, wethAmount, minBPT);

		_eventName = "LogMintSNoteFromWETH(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(address(this), noteAmount, wethAmount, minBPT);
	}

	/// @notice Begins a cool down period for the sender
	/// @dev This is required to redeem tokens
	function startCoolDown()
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		staking.startCoolDown();

		_eventName = "LogStartCoolDown(address)";
		_eventParam = abi.encode(address(this));
	}

	/// @notice Stops a cool down for the sender
	/// @dev User must start another cool down period in order to call redeemSNote
	function stopCoolDown()
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		staking.stopCoolDown();

		_eventName = "LogStopCoolDown(address)";
		_eventParam = abi.encode(address(this));
	}

	/// @notice Redeems some amount of sNOTE to underlying constituent tokens (ETH and NOTE).
	/// @dev An account must have passed its cool down expiration before they can redeem
	/// @param sNOTEAmount amount of sNOTE to redeem
	/// @param minWETH slippage protection for ETH/WETH amount
	/// @param minNOTE slippage protection for NOTE amount
	/// @param redeemWETH true if redeeming to WETH to ETH
	function redeemSNote(
		uint256 sNOTEAmount,
		uint256 minWETH,
		uint256 minNOTE,
		bool redeemWETH
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		if (sNOTEAmount == type(uint256).max)
			sNOTEAmount = staking.balanceOf(address(this));

		staking.redeem(sNOTEAmount, minWETH, minNOTE, redeemWETH);

		_eventName = "LogRedeemSNote(address,uint256,uint256,uint256,bool)";
		_eventParam = abi.encode(
			address(this),
			sNOTEAmount,
			minWETH,
			minNOTE,
			redeemWETH
		);
	}

	/**
	 * @notice Executes a number of batch actions on the account without getId or setId integration
	 * @dev This method will allow the user to take almost any action on Notional but does not have any
	 * getId or setId integration. This can be used to roll lends and borrows forward.
	 * @param actions a set of BatchActionWithTrades that will be executed for this account
	 */
	function batchActionRaw(BalanceActionWithTrades[] memory actions)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		notional.batchBalanceAndTradeAction(address(this), actions);

		_eventName = "LogBatchActionRaw(address)";
		_eventParam = abi.encode(address(this));
	}
}

contract ConnectV2Notional is NotionalResolver {
	string public name = "Notional-v1.1";
}
