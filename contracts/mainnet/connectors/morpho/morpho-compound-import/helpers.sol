// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import { ComptrollerInterface, CompoundMappingInterface, CETHInterface, CTokenInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	/**
	 * @dev Compound CEth
	 */
	CETHInterface internal constant cEth =
		CETHInterface(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

	/**
	 * @dev Compound Comptroller
	 */
	ComptrollerInterface internal constant troller =
		ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

	/**
	 * @dev Compound Mapping
	 */
	IMorphoLens internal constant morphoLens =
		IMorphoLens(0x930f1b46e1D081Ec1524efD95752bE3eCe51EF67);

	IMorpho internal constant morpho =
		IMorpho(0x8888882f8f843896699869179fB6E4f7e3B58888);

	struct ImportData {
		uint256[] borrowAmts;
		uint256[] supplyAmts;
		address[] borrowTokens;
		address[] supplyTokens;
		CTokenInterface[] borrowCtokens;
		CTokenInterface[] supplyCtokens;
		address[] supplyCtokensAddr;
		address[] borrowCtokensAddr;
	}

	struct ImportInputData {
		address userAccount;
		address[] supplyCTokens;
		address[] borrowCTokens;
		uint256[] flashLoanFees;
	}
}

contract MorphoCompoundHelper is Helpers {
	/**
	 * @notice fetch the borrow details of the user
	 * @dev approve the cToken to spend (borrowed amount of) tokens to allow for repaying later
	 * @param _importInputData the struct containing borrowIds of the users borrowed tokens
	 * @param data struct used to store the final data on which the CompoundHelper contract functions operate
	 * @return ImportData the final value of param data
	 */
	function getBorrowAmounts(
		ImportInputData memory importInputData_,
		ImportData memory data
	) internal returns (ImportData memory) {
		if (importInputData_.borrowCTokens.length > 0) {
			// initialize arrays for borrow data
			uint256 length_ = importInputData_.borrowCTokens.length;
			data.borrowTokens = new address[](_length);
			data.borrowCtokens = new CTokenInterface[](_length);
			data.borrowCtokensAddr = new address[](_length);
			data.borrowAmts = new uint256[](_length);

			// populate the arrays with borrow tokens, cToken addresses and instances, and borrow amounts
			for (uint256 i; i < _length; i++) {
				address cToken_ = importInputData_.borrowCTokens[i];
				CTokenInterface ctoken_ = CTokenInterface(cToken_);

				address token_ = cToken_ == address(cEth)
					? wethAddr
					: ctoken_.underlying();

				require(token_ != address(0), "invalid-ctoken-address");

				data.borrowTokens[i] = token_;
				data.borrowCtokens[i] = ctoken_;
				data.borrowCtokensAddr[i] = cToken_;
				(, , data.borrowAmts[i]) = morphoLens
					.getCurrentBorrowBalanceInOf(
						cToken_,
						importInputData_.userAccount
					);

				// give the morpho approval to spend tokens
				if (token_ != ethAddr && data.borrowAmts[i] > 0) {
					// will be required when repaying the borrow amount on behalf of the user
					TokenInterface(token_).approve(
						address(morpho),
						data.borrowAmts[i]
					);
				}
			}
		}
		return data;
	}

	/**
	 * @notice fetch the supply details of the user
	 * @dev only reads data from blockchain hence view
	 * @param _importInputData the struct containing supplyIds of the users supplied tokens
	 * @param data struct used to store the final data on which the CompoundHelper contract functions operate
	 * @return ImportData the final value of param data
	 */
	function getSupplyAmounts(
		ImportInputData memory importInputData_,
		ImportData memory data
	) internal view returns (ImportData memory) {
		// initialize arrays for supply data
		uint256 length_ = importInputData_.supplyCTokens.length;
		data.supplyTokens = new address[](_length);
		data.supplyCtokens = new CTokenInterface[](_length);
		data.supplyCtokensAddr = new address[](_length);
		data.supplyAmts = new uint256[](_length);

		// populate arrays with supply data (supply tokens address, cToken addresses, cToken instances and supply amounts)
		for (uint256 i; i < _length; i++) {
			address cToken_ = importInputData_.supplyCTokens[i];
			CTokenInterface ctoken_ = CTokenInterface(cToken_);
			address token_ = cToken_ == address(cEth)
				? wethAddr
				: ctoken_.underlying();

			require(token_ != address(0), "invalid-ctoken-address");

			data.supplyTokens[i] = token_;
			data.supplyCtokens[i] = ctoken_;
			data.supplyCtokensAddr[i] = (cToken_);
			(, , data.supplyAmts[i]) = morpho.getCurrentSupplyBalanceInOf(
				cToken_,
				importInputData_.userAccount
			);
		}
		return data;
	}

	/**
	 * @notice repays the debt taken by user on Compound on its behalf to free its collateral for transfer
	 * @dev uses the cEth contract for ETH repays, otherwise the general cToken interface
	 * @param _userAccount the user address for which debt is to be repayed
	 * @param _cTokenContracts array containing all interfaces to the cToken contracts in which the user has debt positions
	 * @param _borrowAmts array containing the amount borrowed for each token
	 */
	function _paybackDebt(
		address userAccount_,
		address[] memory cTokens_,
		uint256[] memory borrowAmts_
	) internal {
		uint256 length_ = cTokens.length;
		for (uint256 i; i < length; ++i) {
			if (borrowAmts_[i] > 0) {
				morpho.repay(cTokens[i], userAccount_, borrowAmts_[i]);
			}
		}
	}

	/**
	 * @notice used to transfer user's supply position on Compound to DSA
	 * @dev uses the transferFrom token in cToken contracts to transfer positions, requires approval from user first
	 * @param _userAccount address of the user account whose position is to be transferred
	 * @param _cTokenContracts array containing all interfaces to the cToken contracts in which the user has supply positions
	 * @param _amts array containing the amount supplied for each token
	 */
	function _transferCTokensToDsa(
		address userAccount_,
		CTokenInterface[] memory cTokenContracts_,
		uint256[] memory supplyAmts_
	) internal {
		uint256 length_ = cTokens_.length;
		for (uint256 i; i < length_; ++i)
			if (supplyAmts_[i] > 0)
				require(
					cTokenContracts_[i].transferFrom(
						userAccount_,
						address(this),
						supplyAmts_[i]
					),
					"ctoken-transfer-failed-allowance?"
				);
	}

	/**
	 * @notice borrows the user's debt positions from Morpho via DSA, so that its debt positions get imported to DSA
	 * @dev borrows some extra amount than the original position to cover the flash loan fee
	 * @param cTokens_ array containing cToken addresses in which the user has debt positions
	 * @param borrowAmts_ array containing the amounts the user had borrowed originally from Morpho-Compound
	 * @param flashLoanFees_ flash loan fees.
	 */
	function _borrowDebtPosition(
		address[] memory cTokens_,
		uint256[] memory borrowAmts_,
		uint256[] memory flashLoanFees_
	) internal {
		uint256 length_ = cTokens_.length;
		for (uint256 i; i < length_; ++i)
			if (borrowAmts_[i] > 0)
				morpho.borrow(
					cTokens_[i],
					add(borrowAmts_[i], flashLoanFees_[i])
				);
	}
}
