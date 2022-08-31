//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Compound.
 * @dev Lending & Borrowing.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { CometInterface } from "./interface.sol";
import "hardhat/console.sol";

abstract contract CompoundIIIResolver is Events, Helpers {
	/**
	 * @dev Deposit base asset or collateral asset supported by the market.
	 * @notice Deposit a token to Compound for lending / collaterization.
	 * @param market The address of the market where to supply.
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
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		require(
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(_token);

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, _amt);
		}

		approve(tokenContract, market, _amt);

		CometInterface(market).supply(_token, _amt);

		setUint(setId, _amt);

		_eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, _amt, getId, setId);
	}

	/**
	 * @dev Deposit base asset or collateral asset supported by the market on behalf of 'to'.
	 * @notice Deposit a token to Compound for lending / collaterization on behalf of 'to'.
	 * @param market The address of the market where to supply.
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
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		require(
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(_token);

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, _amt);
		}

		approve(tokenContract, market, _amt);

		CometInterface(market).supplyTo(to, _token, _amt);

		setUint(setId, _amt);

		_eventName = "LogDepositOnBehalf(address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, to, _amt, getId, setId);
	}

	/**
	 * @dev Deposit base asset or collateral asset supported by the market from 'from' address and update the position of 'to'.
	 * @notice Deposit a token to Compound for lending / collaterization from a address and update the position of 'to'.
	 * @param market The address of the market from where to supply.
	 * @param token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param from The address from where amount is to be supplied.
	 * @param to The address on account of which the supply is made or whose positions are updated.
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function depositFrom(
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
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		require(
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(_token);

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, _amt);
		}

		approve(tokenContract, market, _amt);

		CometInterface(market).supplyFrom(from, to, _token, _amt);

		setUint(setId, _amt);

		_eventName = "LogDepositFrom(address,address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, from, to, _amt, getId, setId);
	}

	/**
	 * @dev Withdraw base/collateral asset or borrow base asset.
	 * @notice Withdraw base token or deposited token from Compound.
	 * @param market The address of the market from where to withdraw.
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
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		require(
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(_token);

		uint256 initialBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token
		);

		CometInterface(market).withdraw(_token, _amt);

		uint256 finalBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token
		);

		_amt = sub(finalBal, initialBal);

		convertWethToEth(isEth, tokenContract, _amt);

		setUint(setId, _amt);

		_eventName = "LogWithdraw(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, _amt, getId, setId);
	}

	/**
	 * @dev Withdraw base/collateral asset or borrow base asset and transfer to 'to'.
	 * @notice Withdraw base token or deposited token from Compound on behalf of an address and transfer to 'to'.
	 * @param market The address of the market from where to withdraw.
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
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(uint256 _amt, uint256 _setId) = _borrowOrWithdraw(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: address(0),
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			})
		);

		_eventName = "LogWithdrawOnBehalf(address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, to, _amt, getId, _setId);
	}

	/**
	 * @dev Withdraw base/collateral asset or borrow base asset from an account and transfer to 'to'.
	 * @notice Withdraw base token or deposited token from Compound from an address and transfer to 'to'.
	 * @param market The address of the market from where to withdraw.
	 * @param token The address of the token to be withdrawn. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param from The address from where asset is to be withdrawed.
	 * @param to The address to which the borrowed assets are to be transferred.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdrawFrom(
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
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(uint256 _amt, uint256 _setId) = _borrowOrWithdraw(
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

		_eventName = "LogWithdrawFrom(address,address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, token, from, to, _amt, getId, _setId);
	}

	/**
	 * @dev Borrow base asset.
	 * @notice Withdraw base token from Compound.
	 * @param market The address of the market from where to withdraw.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function borrow(
		address market,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		require(market != address(0), "invalid market address");

		address token = getBaseToken(market);
		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		console.log(_amt);

		TokenInterface tokenContract = TokenInterface(_token);

		uint256 initialBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			_token
		);
		CometInterface(market).withdraw(_token, _amt);

		uint256 finalBal = getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			_token
		);

		_amt = sub(finalBal, initialBal);

		convertWethToEth(isEth, tokenContract, _amt);

		setUint(setId, _amt);

		_eventName = "LogBorrow(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, _amt, getId, setId);
	}

	/**
	 * @dev Borrow base asset and transfer to 'to' account.
	 * @notice Withdraw base token from Compound on behalf of an address.
	 * @param market The address of the market from where to withdraw.
	 * @param to The address to which the borrowed asset is transferred.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
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
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(uint256 _amt, uint256 _setId) = _borrowOrWithdraw(
			BorrowWithdrawParams({
				market: market,
				token: getBaseToken(market),
				from: address(0),
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			})
		);
		_eventName = "LogBorrowOnBehalf(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, to, _amt, getId, _setId);
	}

	/**
	 * @dev Borrow base asset from 'from' and transfer to 'to'.
	 * @notice Withdraw base token or deposited token from Compound.
	 * @param market The address of the market from where to withdraw.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param from The address from where asset is to be withdrawed.
	 * @param to The address to which the borrowed assets are to be transferred.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function borrowFrom(
		address market,
		address from,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(uint256 _amt, uint256 _setId) = _borrowOrWithdraw(
			BorrowWithdrawParams({
				market: market,
				token: getBaseToken(market),
				from: from,
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			})
		);
		_eventName = "LogBorrowFrom(address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, from, to, _amt, getId, _setId);
	}

	/**
	 * @dev Repays entire borrow of the base asset.
	 * @notice Repays an entire borrow of the base asset.
	 * @param market The address of the market from where to withdraw.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function payback(address market, uint256 setId)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(market != address(0), "invalid market address");

		address token = getBaseToken(market);
		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(_token);

		approve(tokenContract, market, uint256(-1));
		uint256 _amt = CometInterface(market).borrowBalanceOf(address(this));

		CometInterface(market).supply(_token, uint256(-1));

		setUint(setId, _amt);

		_eventName = "LogPayback(address,address,uint256,uint256)";
		_eventParam = abi.encode(market, token, _amt, setId);
	}

	/**
	 * @dev Repays entire borrow of the base asset on behalf of 'to'.
	 * @notice Repays an entire borrow of the base asset on behalf of 'to'.
	 * @param market The address of the market from where to withdraw.
	 * @param to The address on behalf of which the borrow is to be repaid.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function paybackOnBehalf(
		address market,
		address to,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(market != address(0), "invalid market address");

		address token = getBaseToken(market);
		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(_token);

		approve(tokenContract, market, uint256(-1));
		uint256 _amt = CometInterface(market).borrowBalanceOf(to);

		CometInterface(market).supplyTo(to, _token, uint256(-1));

		setUint(setId, _amt);

		_eventName = "LogPaybackOnBehalf(address,address,address,uint256,uint256)";
		_eventParam = abi.encode(market, token, to, _amt, setId);
	}

	/**
	 * @dev Repays entire borrow of the base asset form 'from' on behalf of 'to'.
	 * @notice Repays an entire borrow of the base asset on behalf of 'to'.
	 * @param market The address of the market from where to withdraw.
	 * @param from The address from which the borrow has to be repaid on behalf of 'to'.
	 * @param to The address on behalf of which the borrow is to be repaid.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function paybackFrom(
		address market,
		address from,
		address to,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(market != address(0), "invalid market address");

		address token = getBaseToken(market);
		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(_token);

		approve(tokenContract, market, uint256(-1));
		uint256 _amt = CometInterface(market).borrowBalanceOf(to);

		CometInterface(market).supplyFrom(from, to, _token, uint256(-1));

		setUint(setId, _amt);

		_eventName = "LogPaybackFrom(address,address,address,address,uint256,uint256)";
		_eventParam = abi.encode(market, token, from, to, _amt, setId);
	}

	/**
	 * @dev Buy collateral asset absorbed, from the market.
	 * @notice Buy collateral asset to increase protocol base reserves until targetReserves is reached.
	 * @param market The address of the market from where to withdraw.
	 * @param asset The collateral asset to purachase.
	 * @param dest The address on to transfer the purchased assets.
	 * @param minCollateralAmt Minimum amount of collateral expected to be received.
	 * @param baseAmt Amount of base asset to be sold for collateral.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
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
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, baseAmt);

		bool isEth = asset == ethAddr;
		address _token = isEth ? wethAddr : asset;
		TokenInterface tokenContract = TokenInterface(_token);

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, _amt);
		}

		CometInterface(market).buyCollateral(
			asset,
			minCollateralAmt,
			_amt,
			dest
		);

		uint256 collAmt = CometInterface(market).quoteCollateral(asset, _amt);
		setUint(setId, _amt);

		_eventName = "LogBuyCollateral(address,address,uint256,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			market,
			asset,
			baseAmt,
			minCollateralAmt,
			collAmt,
			getId,
			setId
		);
	}

	/**
	 * @dev Claim rewards and interests accrued in supplied/borrowed base asset.
	 * @notice Claim rewards and interests accrued.
	 * @param market The address of the market from where to withdraw.
	 * @param account The account of which the rewards are to be claimed.
	 * @param accrue Should accrue the rewards and interest before claiming.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function claimRewards(
		address market,
		address account,
		bool accrue,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		cometRewards.claim(market, account, accrue);

		//in reward token decimals
		uint256 totalRewardsClaimed = cometRewards.rewardsClaimed(
			market,
			account
		);
		setUint(setId, totalRewardsClaimed);

		_eventName = "LogRewardsClaimed(address,address,uint256,uint256,bool)";
		_eventParam = abi.encode(
			market,
			account,
			totalRewardsClaimed,
			setId,
			accrue
		);
	}

	/**
	 * @dev Claim rewards and interests accrued in supplied/borrowed base asset.
	 * @notice Claim rewards and interests accrued and transfer to dest address.
	 * @param market The address of the market from where to withdraw.
	 * @param account The account of which the rewards are to be claimed.
	 * @param dest The account where to transfer the claimed rewards.
	 * @param accrue Should accrue the rewards and interest before claiming.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function claimRewardsTo(
		address market,
		address account,
		address dest,
		bool accrue,
		uint256 setId
	) public returns (string memory _eventName, bytes memory _eventParam) {
		cometRewards.claimTo(market, account, dest, accrue);

		//in reward token decimals
		uint256 totalRewardsClaimed = cometRewards.rewardsClaimed(
			market,
			account
		);
		setUint(setId, totalRewardsClaimed);

		_eventName = "LogRewardsClaimedTo(address,address,address,uint256,uint256,bool)";
		_eventParam = abi.encode(
			market,
			account,
			dest,
			totalRewardsClaimed,
			setId,
			accrue
		);
	}

	/**
	 * @dev Transfer base asset to dest address from this account.
	 * @notice Transfer base asset to dest address from caller's account.
	 * @param market The address of the market where to supply.
	 * @param dest The account where to transfer the base assets.
	 * @param amount The amount of the base token to transfer. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function transferBase(
		address market,
		address dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amount);
		require(market != address(0), "invalid market address");

		address token = getBaseToken(market);
		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(_token);

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, _amt);
		}

		_transfer(market, _token, address(0), dest, _amt);

		setUint(setId, _amt);

		_eventName = "LogTransferBase(address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, dest, _amt, getId, setId);
	}

	/**
	 * @dev Transfer base asset to dest address from src account.
	 * @notice Transfer base asset to dest address from src account.
	 * @param market The address of the market where to supply.
	 * @param src The account to transfer the base assets from.
	 * @param dest The account to transfer the base assets to.
	 * @param amount The amount of the base token to transfer. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function transferBaseFrom(
		address market,
		address src,
		address dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amount);
		require(market != address(0), "invalid market address");

		address token = getBaseToken(market);
		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(_token);

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, _amt);
		}

		_transfer(market, _token, src, dest, _amt);

		setUint(setId, _amt);

		_eventName = "LogTransferBaseFrom(address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, src, dest, _amt, getId, setId);
	}

	/**
	 * @dev Transfer collateral asset to dest address from this account.
	 * @notice Transfer collateral asset to dest address from caller's account.
	 * @param market The address of the market where to supply.
	 * @param token The collateral asset to transfer to dest address.
	 * @param dest The account where to transfer the base assets.
	 * @param amount The amount of the collateral token to transfer. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
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
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amount);
		require(
			market != address(0) && token != address(0),
			"invalid market address"
		);

		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(_token);

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, _amt);
		}

		_transfer(market, _token, address(0), dest, _amt);

		setUint(setId, _amt);

		_eventName = "LogTransferAsset(address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, _token, dest, _amt, getId, setId);
	}

	/**
	 * @dev Transfer collateral asset to dest address from src account.
	 * @notice Transfer collateral asset to dest address from src's account.
	 * @param market The address of the market where to supply.
	 * @param token The collateral asset to transfer to dest address.
	 * @param src The account from where to transfer the collaterals.
	 * @param dest The account where to transfer the collateral assets.
	 * @param amount The amount of the collateral token to transfer. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function transferAssetFrom(
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
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amount);
		require(market != address(0), "invalid market address");

		address token = getBaseToken(market);
		bool isEth = token == ethAddr;
		address _token = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(_token);

		if (isEth) {
			convertEthToWeth(isEth, tokenContract, _amt);
		}

		_transfer(market, _token, src, dest, _amt);

		setUint(setId, _amt);

		_eventName = "LogTransferAssetFrom(address,address,address,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(market, _token, src, dest, _amt, getId, setId);
	}

	/**
	 * @dev Allow/Disallow managers to handle position.
	 * @notice Authorize/Remove managers to perform write operations for the position.
	 * @param market The address of the market where to supply.
	 * @param manager The address to be authorized.
	 * @param isAllowed Whether to allow or disallow the manager.
	 */
	function allow(
		address market,
		address manager,
		bool isAllowed
	) external returns (string memory _eventName, bytes memory _eventParam) {
		CometInterface(market).allow(manager, isAllowed);
		_eventName = "LogAllow(address,address,bool)";
		_eventParam = abi.encode(market, manager, isAllowed);
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
	function allowWithPermit(
		address market,
		address owner,
		address manager,
		bool isAllowed,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (string memory _eventName, bytes memory _eventParam) {
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
		_eventName = "LogAllowWithPermit(address,address,address,uint256,uint256,uint256,uint256,uint256,bool)";
		_eventParam = abi.encode(
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
}

contract ConnectV3Compound is CompoundIIIResolver {
	string public name = "Compound-v1.0";
}
