// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Ubiquity.
 * @dev Ubiquity Dollar (uAD).
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { IUbiquityBondingV2, IUbiquityMetaPool, I3Pool } from "./interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract UbiquityResolver is Helpers, Events {
	/**
	 * @dev Deposit into Ubiquity protocol
	 * @notice 3POOL (DAI / USDC / USDT) => METAPOOL (3CRV / uAD) => uAD3CRV-f => Ubiquity BondingShare
	 * @notice STEP 1 : 3POOL (DAI / USDC / USDT) => 3CRV
	 * @notice STEP 2 : METAPOOL(3CRV / UAD) => uAD3CRV-f
	 * @notice STEP 3 : uAD3CRV-f => Ubiquity BondingShare
	 * @param token Token deposited : DAI, USDC, USDT, 3CRV, uAD or uAD3CRV-f
	 * @param amount Amount of tokens to deposit (For max: `uint256(-1)`)
	 * @param durationWeeks Duration in weeks tokens will be locked (4-208)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the bonding share id of tokens deposited.
	 */
	function deposit(
		address token,
		uint256 amount,
		uint256 durationWeeks,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		address UAD3CRVf = getUADCRV3();
		bool[6] memory tok = [
			token == DAI, // 0
			token == USDC, // 1
			token == USDT, // 2
			token == CRV3, // 3
			token == getUAD(), // 4
			token == UAD3CRVf // 5
		];

		require(
			// DAI / USDC / USDT / CRV3 / UAD / UAD3CRVF
			tok[0] || tok[1] || tok[2] || tok[3] || tok[4] || tok[5],
			"Invalid token: must be DAI, USDC, USDT, 3CRV, uAD or uAD3CRV-f"
		);

		uint256 _amount = getUint(getId, amount);
		uint256 lpAmount;

		// Full balance if amount = -1
		if (_amount == uint256(-1)) {
			_amount = getTokenBal(TokenInterface(token));
		}

		// STEP 1 : SwapTo3CRV : Deposit DAI, USDC or USDT into 3Pool to get 3Crv LPs
		// DAI / USDC / USDT
		if (tok[0] || tok[1] || tok[2]) {
			uint256[3] memory amounts1;

			if (tok[0]) amounts1[0] = _amount;
			else if (tok[1]) amounts1[1] = _amount;
			else if (tok[2]) amounts1[2] = _amount;

			approve(TokenInterface(token), Pool3, _amount);
			I3Pool(Pool3).add_liquidity(amounts1, 0);
		}

		// STEP 2 : ProvideLiquidityToMetapool : Deposit in uAD3CRV pool to get uAD3CRV-f LPs
		// DAI / USDC / USDT / CRV3 / UAD
		if (tok[0] || tok[1] || tok[2] || tok[3] || tok[4]) {
			uint256[2] memory amounts2;
			address token2 = token;
			uint256 _amount2;

			if (tok[4]) {
				_amount2 = _amount;
				amounts2[0] = _amount2;
			} else {
				if (tok[3]) {
					_amount2 = _amount;
				} else {
					token2 = CRV3;
					_amount2 = getTokenBal(TokenInterface(token2));
				}
				amounts2[1] = _amount2;
			}

			approve(TokenInterface(token2), UAD3CRVf, _amount2);
			lpAmount = IUbiquityMetaPool(UAD3CRVf).add_liquidity(amounts2, 0);
		}

		// STEP 3 : Farm/ApeIn : Deposit uAD3CRV-f LPs into UbiquityBondingV2 and get Ubiquity Bonding Shares
		// UAD3CRVF
		if (tok[5]) {
			lpAmount = _amount;
		}

		address bonding = ubiquityManager.bondingContractAddress();
		approve(TokenInterface(UAD3CRVf), bonding, lpAmount);
		uint256 bondingShareId = IUbiquityBondingV2(bonding).deposit(
			lpAmount,
			durationWeeks
		);

		setUint(setId, bondingShareId);

		_eventName = "LogDeposit(address,address,uint256,uint256,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			address(this),
			token,
			amount,
			bondingShareId,
			lpAmount,
			durationWeeks,
			getId,
			setId
		);
	}

	/**
	 * @dev Withdraw from Ubiquity protocol
	 * @notice Ubiquity BondingShare => uAD3CRV-f => METAPOOL (3CRV / uAD) => 3POOL (DAI / USDC / USDT)
	 * @notice STEP 1 : Ubiquity BondingShare  => uAD3CRV-f
	 * @notice STEP 2 : uAD3CRV-f => METAPOOL(3CRV / UAD)
	 * @notice STEP 3 : 3CRV => 3POOL (DAI / USDC / USDT)
	 * @param bondingShareId Bonding Share Id to withdraw
	 * @param token Token to withdraw to : DAI, USDC, USDT, 3CRV, uAD or uAD3CRV-f
	 * @param getId ID
	 * @param setId ID
	 */
	function withdraw(
		uint256 bondingShareId,
		address token,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		address UAD3CRVf = getUADCRV3();
		bool[6] memory tok = [
			token == DAI, // 0
			token == USDC, // 1
			token == USDT, // 2
			token == CRV3, // 3
			token == getUAD(), // 4
			token == UAD3CRVf // 5
		];

		require(
			// DAI / USDC / USDT / CRV3 / UAD / UAD3CRVF
			tok[0] || tok[1] || tok[2] || tok[3] || tok[4] || tok[5],
			"Invalid token: must be DAI, USDC, USDT, 3CRV, uAD or uAD3CRV-f"
		);

		uint256 _bondingShareId = getUint(getId, bondingShareId);

		// Get Bond
		IUbiquityBondingV2.Bond memory bond = IUbiquityBondingV2(
			ubiquityManager.bondingShareAddress()
		).getBond(_bondingShareId);

		require(address(this) == bond.minter, "Not bond owner");

		// STEP 1 : Withdraw Ubiquity Bonding Shares to get back uAD3CRV-f LPs
		address bonding = ubiquityManager.bondingContractAddress();
		IUbiquityBondingV2(bonding).removeLiquidity(
			bond.lpAmount,
			_bondingShareId
		);

		// STEP 2 : Withdraw uAD3CRV-f LPs to get back uAD or 3Crv
		// DAI / USDC / USDT / CRV3 / UAD
		if (tok[0] || tok[1] || tok[2] || tok[3] || tok[4]) {
			uint256 amount2 = getTokenBal(TokenInterface(UAD3CRVf));
			IUbiquityMetaPool(UAD3CRVf).remove_liquidity_one_coin(
				amount2,
				tok[4] ? 0 : 1,
				0
			);
		}

		// STEP 3 : Withdraw  3Crv LPs from 3Pool to get back DAI, USDC or USDT
		// DAI / USDC / USDT
		if (tok[0] || tok[1] || tok[2]) {
			uint256 amount1 = getTokenBal(TokenInterface(CRV3));
			I3Pool(Pool3).remove_liquidity_one_coin(
				amount1,
				tok[0] ? 0 : (tok[1] ? 1 : 2),
				0
			);
		}

		uint256 amount = getTokenBal(TokenInterface(token));

		setUint(setId, amount);
		_eventName = "LogWithdraw(address,uint256,uint256,uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			address(this),
			_bondingShareId,
			bond.lpAmount,
			bond.endBlock,
			token,
			amount,
			getId,
			setId
		);
	}
}

contract ConnectV2Ubiquity is UbiquityResolver {
	string public constant name = "Ubiquity-v1";
}
