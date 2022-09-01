//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Compound III
 * @dev Lending & Borrowing.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
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
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(token_);

		if (token_ == getBaseToken(market)) {
			require(
				CometInterface(market).borrowBalanceOf(to) == 0,
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
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(token_);

		if (token_ == getBaseToken(market)) {
			require(
				CometInterface(market).borrowBalanceOf(to) == 0,
				"debt-not-repaid"
			);
		}

		amt_ = setAmt(market, token_, from, amt_, isEth);

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

		uint256 initialBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token
		);

		amt_ = amt_ == uint256(-1) ? initialBal : amt_;

		if (token_ == getBaseToken(market)) {
			uint256 balance = CometInterface(market).balanceOf(address(this));
			if (balance > 0) {
				require(amt_ <= balance, "withdraw-amt-greater-than-supplies");
			}
		}

		CometInterface(market).withdraw(token_, amt_);

		uint256 finalBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token
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
	function withdrawOnbehalf(
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
		(uint256 amt_, uint256 setId_) = _borrowOrWithdraw(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: address(0),
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			}),
			true
		);

		eventName_ = "LogWithdrawOnBehalf(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, to, amt_, getId, setId_);
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
	function withdrawFromUsingManager(
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
		(uint256 amt_, uint256 setId_) = _borrowOrWithdraw(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: from,
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			}),
			true
		);

		eventName_ = "LogWithdrawFromUsingManager(address,address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, from, to, amt_, getId, setId_);
	}

	/**
	 * @dev Borrow base asset.
	 * @notice Borrow base token from Compound.
	 * @param market The address of the market.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens borrowed.
	 */
	function borrow(
		address market,
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

		address token = getBaseToken(market);
		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(token_);

		uint256 initialBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token_
		);

		amt_ = amt_ == uint256(-1) ? initialBal : amt_;

		if (token_ == getBaseToken(market)) {
			uint256 balance = CometInterface(market).balanceOf(address(this));
			require(balance == 0, "borrow-disabled-when-supplied-base");
		}

		CometInterface(market).withdraw(token_, amt_);

		uint256 finalBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token_
		);

		amt_ = sub(initialBal, finalBal);

		convertWethToEth(isEth, tokenContract, amt_);

		setUint(setId, amt_);

		eventName_ = "LogBorrow(address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, amt_, getId, setId);
	}

	/**
	 * @dev Borrow base asset and transfer to 'to' account.
	 * @notice Borrow base token from Compound on behalf of an address.
	 * @param market The address of the market.
	 * @param to The address to which the borrowed asset is transferred.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens borrowed.
	 */
	function borrowOnBehalf(
		address market,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		(uint256 amt_, uint256 setId_) = _borrowOrWithdraw(
			BorrowWithdrawParams({
				market: market,
				token: getBaseToken(market),
				from: address(0),
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			}),
			false
		);
		eventName_ = "LogBorrowOnBehalf(address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, to, amt_, getId, setId_);
	}

	/**
	 * @dev Borrow base asset from 'from' and transfer to 'to'.
	 * @notice Borrow base token or deposited token from Compound.
	 * @param market The address of the market.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param from The address from where asset is to be withdrawed.
	 * @param to The address to which the borrowed assets are to be transferred.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens borrowed.
	 */
	function borrowFromUsingManager(
		address market,
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
		(uint256 amt_, uint256 setId_) = _borrowOrWithdraw(
			BorrowWithdrawParams({
				market: market,
				token: getBaseToken(market),
				from: from,
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			}),
			false
		);
		eventName_ = "LogBorrowFromUsingManager(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, from, to, amt_, getId, setId_);
	}

	/**
	 * @dev Repays the borrowed base asset.
	 * @notice Repays the borrow of the base asset.
	 * @param market The address of the market.
	 * @param amt The amount to be repaid.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens repaid.
	 */
	function payback(
		address market,
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

		address token = getBaseToken(market);
		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(token_);

		amt_ = amt_ == uint256(-1)
			? TokenInterface(market).balanceOf(address(this))
			: amt_;

		uint256 borrowBal = CometInterface(market).borrowBalanceOf(
			address(this)
		);
		if (borrowBal > 0) {
			require(amt_ <= borrowBal, "repay-amt-greater-than-debt");
		}

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, amt_);
		}
		approve(tokenContract, market, amt_);

		CometInterface(market).supply(token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogPayback(address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, amt_, getId, setId);
	}

	/**
	 * @dev Repays entire borrow of the base asset on behalf of 'to'.
	 * @notice Repays an entire borrow of the base asset on behalf of 'to'.
	 * @param market The address of the market.
	 * @param to The address on behalf of which the borrow is to be repaid.
	 * @param amt The amount to be repaid.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens repaid.
	 */
	function paybackOnBehalf(
		address market,
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
		require(market != address(0), "invalid market address");

		address token = getBaseToken(market);
		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(token_);

		amt_ = amt_ == uint256(-1)
			? TokenInterface(market).balanceOf(to)
			: amt_;

		uint256 borrowBal = CometInterface(market).borrowBalanceOf(to);
		if (borrowBal > 0) {
			require(amt_ <= borrowBal, "repay-amt-greater-than-debt");
		}

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, amt_);
		}

		approve(tokenContract, market, amt_);

		CometInterface(market).supplyTo(to, token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogPaybackOnBehalf(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, to, amt_, getId, setId);
	}

	/**
	 * @dev Repays entire borrow of the base asset form 'from' on behalf of 'to'.
	 * @notice Repays an entire borrow of the base asset on behalf of 'to'. Approve the comet markey
	 * @param market The address of the market.
	 * @param from The address from which the borrow has to be repaid on behalf of 'to'.
	 * @param to The address on behalf of which the borrow is to be repaid.
	 * @param amt The amount to be repaid.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens repaid.
	 */
	function paybackFromUsingManager(
		address market,
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
		require(market != address(0), "invalid market address");

		address token = getBaseToken(market);
		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(token_);

		amt_ = setAmt(market, token_, from, amt_, isEth);

		uint256 borrowBal = CometInterface(market).borrowBalanceOf(to);
		if (borrowBal > 0) {
			require(amt_ <= borrowBal, "repay-amt-greater-than-debt");
		}

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, amt_);
		}

		approve(tokenContract, market, amt_);

		CometInterface(market).supplyFrom(from, to, token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogPaybackFromUsingManager(address,address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, from, to, amt_, getId, setId);
	}

	/**
	 * @dev Buy collateral asset absorbed, from the market.
	 * @notice Buy collateral asset to increase protocol base reserves until targetReserves is reached.
	 * @param market The address of the market from where to withdraw.
	 * @param asset The collateral asset to purachase.
	 * @param dest The address to transfer the purchased assets.
	 * @param minCollateralAmt Minimum amount of collateral expected to be received.
	 * @param baseAmt Amount of base asset to be sold for collateral.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of base tokens sold.
	 */
	function buyCollateral(
		address market,
		address asset,
		address dest,
		uint256 minCollateralAmt,
		uint256 baseAmt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, baseAmt);

		bool isEth = asset == ethAddr;
		address token_ = isEth ? wethAddr : asset;
		TokenInterface tokenContract = TokenInterface(token_);

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, amt_);
		}

		approve(tokenContract, market, amt_);

		CometInterface(market).buyCollateral(
			asset,
			minCollateralAmt,
			amt_,
			dest
		);

		uint256 collAmt = CometInterface(market).quoteCollateral(asset, amt_);
		setUint(setId, amt_);

		eventName_ = "LogBuyCollateral(address,address,uint256,uint256,uint256,uint256,uint256)";
		eventParam_ = abi.encode(
			market,
			asset,
			amt_,
			minCollateralAmt,
			collAmt,
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
			market != address(0) && token != address(0),
			"invalid market address"
		);

		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(token_);

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, amt_);
		}

		amt_ = amt_ == uint256(-1)
			? (
				(token_ == getBaseToken(market))
					? TokenInterface(market).balanceOf(address(this))
					: CometInterface(market)
						.userCollateral(address(this), token_)
						.balance
			)
			: amt_;

		_transfer(market, token_, address(0), dest, amt_);

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
	function transferAssetFromUsingManager(
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
		require(market != address(0), "invalid market address");

		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(token_);

		amt_ = setAmt(market, token_, src, amt_, isEth);

		_transfer(market, token_, src, dest, amt_);

		setUint(setId, amt_);

		eventName_ = "LogTransferAssetFromUsingManager(address,address,address,address,uint256,uint256,uint256)";
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
		eventName_ = "LogAllow(address,address,bool)";
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
		eventName_ = "LogAllowWithPermit(address,address,address,uint256,uint256,uint256,uint256,uint256,bool)";
		eventParam_ = abi.encode(
			market,
			owner,
			manager,
			isAllowed,
			nonce,
			expiry,
			v,
			r,
			s
		);
	}

	function approveMarket(
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
		require(amt > 0, "amount-cannot-be-zero");

		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(token_);

		amt_ = amt_ == uint256(-1)
			? TokenInterface(market).balanceOf(address(this))
			: amt_;

		approve(tokenContract, market, amt_);

		setUint(setId, amt_);

		eventName_ = "LogApproveMarket(address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, amt_, getId, setId);
	}
}

contract ConnectV2CompoundV3 is CompoundV3Resolver {
	string public name = "CompoundV3-v1.0";
}
