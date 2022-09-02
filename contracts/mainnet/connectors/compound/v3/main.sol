//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Compound III
 * @dev Lending & Borrowing.
 */

import { TokenInterface } from "../../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { CometInterface } from "./interface.sol";

abstract contract CompoundV3Resolver is Events, Helpers {
	/**
	 * @dev Deposit base asset or collateral asset supported by the market.
	 * @notice Deposit a token to Compound for lending / collaterization.
	 * @param market The address of the market.
	 * @param token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function deposit(
		address market,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);

		require(
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(token_);

		if (token_ == getBaseToken(market)) {
			require(
				CometInterface(market).borrowBalanceOf(address(this)) == 0,
				"debt-not-repaid"
			);
		}

		if (isEth) {
			amt_ = amt_ == uint256(-1) ? address(this).balance : amt_;
			convertEthToWeth(isEth, tokenContract, amt_);
		} else {
			amt_ = amt_ == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: amt_;
		}
		approve(tokenContract, market, amt_);

		CometInterface(market).supply(token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogDeposit(address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, amt_, getId, setId);
	}

	/**
	 * @dev Deposit base asset or collateral asset supported by the market on behalf of 'to'.
	 * @notice Deposit a token to Compound for lending / collaterization on behalf of 'to'.
	 * @param market The address of the market.
	 * @param token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE).
	 * @param to The address on behalf of which the supply is made.
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function depositOnBehalf(
		address market,
		address token,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);

		require(
			market != address(0) && token != address(0) && to != address(0),
			"invalid market/token/to address"
		);

		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(token_);

		if (token_ == getBaseToken(market)) {
			require(
				CometInterface(market).borrowBalanceOf(to) == 0,
				"to-address-position-debt-not-repaid"
			);
		}

		if (isEth) {
			amt_ = amt_ == uint256(-1) ? address(this).balance : amt_;
			convertEthToWeth(isEth, tokenContract, amt_);
		} else {
			amt_ = amt_ == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: amt_;
		}
		approve(tokenContract, market, amt_);

		CometInterface(market).supplyTo(to, token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogDepositOnBehalf(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, to, amt_, getId, setId);
	}

	/**
	 * @dev Deposit base asset or collateral asset supported by the market from 'from' address and update the position of 'to'.
	 * @notice Deposit a token to Compound for lending / collaterization from a address and update the position of 'to'.
	 * @param market The address of the market.
	 * @param token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param from The address from where amount is to be supplied.
	 * @param to The address on account of which the supply is made or whose positions are updated.
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function depositFromUsingManager(
		address market,
		address token,
		address from,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);

		require(
			market != address(0) && token != address(0) && to != address(0),
			"invalid market/token/to address"
		);
		require(from != address(this), "from-cannot-be-address(this)-use-depositOnBehalf");

		bool isEth = token == ethAddr;
		address token_ = isEth? wethAddr : token;

		if (token_ == getBaseToken(market)) {
			require(
				CometInterface(market).borrowBalanceOf(to) == 0,
				"to-address-position-debt-not-repaid"
			);
		}

		amt_ = _calculateFromAmount(
			market,
			token_,
			from,
			amt_,
			isEth,
			Action.DEPOSIT
		);

		CometInterface(market).supplyFrom(from, to, token_, amt_);
		setUint(setId, amt_);

		eventName_ = "LogDepositFromUsingManager(address,address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, from, to, amt_, getId, setId);
	}

	/**
	 * @dev Withdraw base/collateral asset.
	 * @notice Withdraw base token or deposited token from Compound.
	 * @param market The address of the market.
	 * @param token The address of the token to be withdrawn. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdraw(
		address market,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);

		require(
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(token_);

		uint256 initialBal = _getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token_
		);

		if (token_ == getBaseToken(market)) {
			if (amt_ == uint256(-1)) {
				amt_ = initialBal;
			} else {
				//if there are supplies, ensure withdrawn amount is not greater than supplied i.e can't borrow using withdraw.
				require(amt_ <= initialBal, "withdraw-amt-greater-than-supplies");
			}

			//if borrow balance > 0, there are no supplies so no withdraw, borrow instead.
			require(
				CometInterface(market).borrowBalanceOf(address(this)) == 0,
				"withdraw-disabled-for-zero-supplies"
			);
		} else {
			amt_ = amt_ == uint256(-1) ? initialBal : amt_;
		}

		CometInterface(market).withdraw(token_, amt_);

		uint256 finalBal = _getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token_
		);

		amt_ = sub(initialBal, finalBal);

		convertWethToEth(isEth, tokenContract, amt_);

		setUint(setId, amt_);

		eventName_ = "LogWithdraw(address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, amt_, getId, setId);
	}

	/**
	 * @dev Withdraw base/collateral asset and transfer to 'to'.
	 * @notice Withdraw base token or deposited token from Compound on behalf of an address and transfer to 'to'.
	 * @param market The address of the market.
	 * @param token The address of the token to be withdrawn. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param to The address to which the borrowed assets are to be transferred.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdrawTo(
		address market,
		address token,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		(uint256 amt_, uint256 setId_) = _withdraw(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: address(this),
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			})
		);

		eventName_ = "LogWithdrawTo(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, to, amt_, getId, setId_);
	}

	/**
	 * @dev Withdraw base/collateral asset from an account and transfer to DSA.
	 * @notice Withdraw base token or deposited token from Compound from an address and transfer to DSA.
	 * @param market The address of the market.
	 * @param token The address of the token to be withdrawn. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param from The address from where asset is to be withdrawed.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdrawOnBehalf(
		address market,
		address token,
		address from,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		(uint256 amt_, uint256 setId_) = _withdraw(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: from,
				to: address(this),
				amt: amt,
				getId: getId,
				setId: setId
			})
		);

		eventName_ = "LogWithdrawOnBehalf(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, from, amt_, getId, setId_);
	}

	/**
	 * @dev Withdraw base/collateral asset from an account and transfer to 'to'.
	 * @notice Withdraw base token or deposited token from Compound from an address and transfer to 'to'.
	 * @param market The address of the market.
	 * @param token The address of the token to be withdrawn. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param from The address from where asset is to be withdrawed.
	 * @param to The address to which the borrowed assets are to be transferred.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdrawOnBehalfAndTransfer(
		address market,
		address token,
		address from,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		(uint256 amt_, uint256 setId_) = _withdraw(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: from,
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			})
		);

		eventName_ = "LogWithdrawOnBehalfAndTransfer(address,address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, from, to, amt_, getId, setId_);
	}

	/**
	 * @dev Borrow base asset.
	 * @notice Borrow base token from Compound.
	 * @param market The address of the market.
	 * @param token The address of the token to be borrowed. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of base token to borrow.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens borrowed.
	 */
	function borrow(
		address market,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);

		require(market != address(0), "invalid market address");

		bool isEth = token == ethAddr;
		address token_ = getBaseToken(market);
		require(token == token_ || isEth, "invalid-token");

		TokenInterface tokenContract = TokenInterface(token_);

		require(
			CometInterface(market).balanceOf(address(this)) == 0,
			"borrow-disabled-when-supplied-base"
		);

		uint256 initialBal = CometInterface(market).borrowBalanceOf(
			address(this)
		);

		CometInterface(market).withdraw(token_, amt_);

		uint256 finalBal = CometInterface(market).borrowBalanceOf(
			address(this)
		);

		amt_ = sub(finalBal, initialBal);

		convertWethToEth(isEth, tokenContract, amt_);

		setUint(setId, amt_);

		eventName_ = "LogBorrow(address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, amt_, getId, setId);
	}

	/**
	 * @dev Borrow base asset and transfer to 'to' account.
	 * @notice Borrow base token from Compound on behalf of an address.
	 * @param market The address of the market.
	 * @param token The address of the token to be borrowed. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param to The address to which the borrowed asset is transferred.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens borrowed.
	 */
	function borrowTo(
		address market,
		address token,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		require(
			token == ethAddr || token == getBaseToken(market),
			"invalid-token"
		);
		(uint256 amt_, uint256 setId_) = _borrow(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: address(this),
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			})
		);
		eventName_ = "LogBorrowTo(address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, to, amt_, getId, setId_);
	}

	/**
	 * @dev Borrow base asset from 'from' and transfer to 'to'.
	 * @notice Borrow base token or deposited token from Compound.
	 * @param market The address of the market.
	 * @param token The address of the token to be borrowed. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param from The address from where asset is to be withdrawed.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens borrowed.
	 */
	function borrowOnBehalf(
		address market,
		address token,
		address from,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		require(
			token == ethAddr || token == getBaseToken(market),
			"invalid-token"
		);
		(uint256 amt_, uint256 setId_) = _borrow(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: from,
				to: address(this),
				amt: amt,
				getId: getId,
				setId: setId
			})
		);
		eventName_ = "LogBorrowOnBehalf(address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, from, amt_, getId, setId_);
	}

	/**
	 * @dev Borrow base asset from 'from' and transfer to 'to'.
	 * @notice Borrow base token or deposited token from Compound.
	 * @param market The address of the market.
	 * @param token The address of the token to be borrowed. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param from The address from where asset is to be withdrawed.
	 * @param to The address to which the borrowed assets are to be transferred.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens borrowed.
	 */
	function borrowOnBehalfAndTransfer(
		address market,
		address token,
		address from,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		require(
			token == ethAddr || token == getBaseToken(market),
			"invalid-token"
		);
		(uint256 amt_, uint256 setId_) = _borrow(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: from,
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			})
		);
		eventName_ = "LogBorrowOnBehalfAndTransfer(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, from, to, amt_, getId, setId_);
	}

	/**
	 * @dev Repays the borrowed base asset.
	 * @notice Repays the borrow of the base asset.
	 * @param market The address of the market.
	 * @param token The address of the token to be repaid. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount to be repaid.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens repaid.
	 */
	function payback(
		address market,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);
		require(
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address token_ = getBaseToken(market);
		require(token == token_ || isEth, "invalid-token");

		TokenInterface tokenContract = TokenInterface(token_);

		uint256 borrowedBalance_ = CometInterface(market).borrowBalanceOf(
			address(this)
		);

		if (amt_ == uint256(-1)) {
			amt_ = borrowedBalance_;
		} else {
			require(
				amt_ <= borrowedBalance_,
				"payback-amt-greater-than-borrows"
			);
		}

		//if supply balance > 0, there are no borrowing so no repay, supply instead.
		require(
			CometInterface(market).balanceOf(address(this)) == 0,
			"cannot-repay-when-supplied"
		);

		convertEthToWeth(isEth, tokenContract, amt_);
		approve(tokenContract, market, amt_);

		CometInterface(market).supply(token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogPayback(address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, amt_, getId, setId);
	}

	/**
	 * @dev Repays borrow of the base asset on behalf of 'to'.
	 * @notice Repays borrow of the base asset on behalf of 'to'.
	 * @param market The address of the market.
	 * @param token The address of the token to be repaid. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param to The address on behalf of which the borrow is to be repaid.
	 * @param amt The amount to be repaid.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens repaid.
	 */
	function paybackOnBehalf(
		address market,
		address token,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);
		require(
			market != address(0) && token != address(0) && to != address(0),
			"invalid market/token/to address"
		);

		address token_ = getBaseToken(market);
		bool isEth = token == ethAddr;
		require(token == token_ || isEth, "invalid-token");

		TokenInterface tokenContract = TokenInterface(token_);

		uint256 borrowedBalance_ = CometInterface(market).borrowBalanceOf(to);

		if (amt_ == uint256(-1)) {
			amt_ = borrowedBalance_;
		} else {
			require(
				amt_ <= borrowedBalance_,
				"payback-amt-greater-than-borrows"
			);
		}

		//if supply balance > 0, there are no borrowing so no repay, supply instead.
		require(
			CometInterface(market).balanceOf(to) == 0,
			"cannot-repay-when-supplied"
		);

		convertEthToWeth(isEth, tokenContract, amt_);
		approve(tokenContract, market, amt_);

		CometInterface(market).supplyTo(to, token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogPaybackOnBehalf(address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, to, amt_, getId, setId);
	}

	/**
	 * @dev Repays borrow of the base asset form 'from' on behalf of 'to'.
	 * @notice Repays borrow of the base asset on behalf of 'to'. 'From' address must approve the comet market.
	 * @param market The address of the market.
	 * @param token The address of the token to be repaid. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param from The address from which the borrow has to be repaid on behalf of 'to'.
	 * @param to The address on behalf of which the borrow is to be repaid.
	 * @param amt The amount to be repaid.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens repaid.
	 */
	function paybackFromUsingManager(
		address market,
		address token,
		address from,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);
		require(
			market != address(0) && token != address(0) && to != address(0),
			"invalid market/token/to address"
		);
		require(from != address(this), "from-cannot-be-address(this)-use-paybackOnBehalf");

		address token_ = getBaseToken(market);
		bool isEth = token == ethAddr;
		require(token == token_ || isEth, "invalid-token");

		if (amt_ == uint256(-1)) {
			amt_ = _calculateFromAmount(
				market,
				token_,
				from,
				amt_,
				isEth,
				Action.REPAY
			);
		} else {
			uint256 borrowedBalance_ = CometInterface(market).borrowBalanceOf(to);
			require(
				amt_ <= borrowedBalance_,
				"payback-amt-greater-than-borrows"
			);
		}

		//if supply balance > 0, there are no borrowing so no repay, withdraw instead.
		require(
			CometInterface(market).balanceOf(to) == 0,
			"cannot-repay-when-supplied"
		);

		CometInterface(market).supplyFrom(from, to, token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogPaybackFromUsingManager(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, from, to, amt_, getId, setId);
	}

	/**
	 * @dev Buy collateral asset absorbed, from the market.
	 * @notice Buy collateral asset to increase protocol base reserves until targetReserves is reached.
	 * @param market The address of the market from where to withdraw.
	 * @param sellToken base token. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param buyAsset The collateral asset to purachase. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param unitAmt Minimum amount of collateral expected to be received.
	 * @param baseSellAmt Amount of base asset to be sold for collateral.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of base tokens sold.
	 */
	function buyCollateral(
		address market,
		address sellToken,
		address buyAsset,
		uint256 unitAmt,
		uint256 baseSellAmt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		(eventName_, eventParam_) = _buyCollateral(
			BuyCollateralData({
				market: market,
				sellToken: sellToken,
				buyAsset: buyAsset,
				unitAmt: unitAmt,
				baseSellAmt: baseSellAmt
			}),
			getId,
			setId
		);
	}

	/**
	 * @dev Transfer base/collateral or base asset to dest address from this account.
	 * @notice Transfer base/collateral asset to dest address from caller's account.
	 * @param market The address of the market.
	 * @param token The collateral asset to transfer to dest address.
	 * @param dest The account where to transfer the base assets.
	 * @param amount The amount of the collateral token to transfer. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens transferred.
	 */
	function transferAsset(
		address market,
		address token,
		address dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amount);
		require(
			market != address(0) && token != address(0) && dest != address(0),
			"invalid market/token/to address"
		);

		address token_ = token == ethAddr ? wethAddr : token;

		amt_ = amt_ == uint256(-1) ? _getAccountSupplyBalanceOfAsset(address(this), market, token) : amt_;

		CometInterface(market).transferAssetFrom(address(this), dest, token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogTransferAsset(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token_, dest, amt_, getId, setId);
	}

	/**
	 * @dev Transfer collateral or base asset to dest address from src account.
	 * @notice Transfer collateral asset to dest address from src's account.
	 * @param market The address of the market.
	 * @param token The collateral asset to transfer to dest address.
	 * @param src The account from where to transfer the collaterals.
	 * @param dest The account where to transfer the collateral assets.
	 * @param amount The amount of the collateral token to transfer. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens transferred.
	 */
	function transferAssetOnBehalf(
		address market,
		address token,
		address src,
		address dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amount);
		require(
			market != address(0) && token != address(0) && dest != address(0),
			"invalid market/token/to address"
		);

		address token_ = token == ethAddr ? wethAddr : token;

		amt_ = amt_ == uint256(-1) ? _getAccountSupplyBalanceOfAsset(src, market, token) : amt_;

		CometInterface(market).transferAssetFrom(src, dest, token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogTransferAssetOnBehalf(address,address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token_, src, dest, amt_, getId, setId);
	}

	/**
	 * @dev Allow/Disallow managers to handle position.
	 * @notice Authorize/Remove managers to perform write operations for the position.
	 * @param market The address of the market where to supply.
	 * @param manager The address to be authorized.
	 * @param isAllowed Whether to allow or disallow the manager.
	 */
	function toggleAccountManager(
		address market,
		address manager,
		bool isAllowed
	) external returns (string memory eventName_, bytes memory eventParam_) {
		CometInterface(market).allow(manager, isAllowed);
		eventName_ = "LogToggleAccountManager(address,address,bool)";
		eventParam_ = abi.encode(market, manager, isAllowed);
	}

	/**
	 * @dev Allow/Disallow managers to handle owner's position.
	 * @notice Authorize/Remove managers to perform write operations for owner's position.
	 * @param market The address of the market where to supply.
	 * @param owner The authorizind owner account.
	 * @param manager The address to be authorized.
	 * @param isAllowed Whether to allow or disallow the manager.
	 * @param nonce Signer's nonce.
	 * @param expiry The duration for which to permit the manager.
	 * @param v Recovery byte of the signature.
	 * @param r Half of the ECDSA signature pair.
	 * @param s Half of the ECDSA signature pair.
	 */
	function toggleAccountManagerWithPermit(
		address market,
		address owner,
		address manager,
		bool isAllowed,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (string memory eventName_, bytes memory eventParam_) {
		CometInterface(market).allowBySig(
			owner,
			manager,
			isAllowed,
			nonce,
			expiry,
			v,
			r,
			s
		);
		eventName_ = "LogToggleAccountManagerWithPermit(address,address,address,bool,uint256,uint256,uint8,bytes32,bytes32)";
		eventParam_ = abi.encode(
			market,
			owner,
			manager,
			isAllowed,
			expiry,
			nonce,
			v,
			r,
			s
		);
	}
}

contract ConnectV2CompoundV3 is CompoundV3Resolver {
	string public name = "CompoundV3-v1.0";
}
