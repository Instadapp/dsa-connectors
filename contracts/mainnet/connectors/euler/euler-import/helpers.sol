//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import { Basic } from "../../../common/basic.sol";
import "./interface.sol";

contract EulerHelpers is Basic {
	/**
	 * @dev Euler's Market Module
	 */
	IEulerMarkets internal constant markets =
		IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

	/**
	 * @dev Euler's Execution Module
	 */
	IEulerExecute internal constant eulerExec =
		IEulerExecute(0x59828FdF7ee634AaaD3f58B19fDBa3b03E2D9d80);

	/**
	 * @dev Compute sub account address.
	 * @notice Compute sub account address from sub-account id
	 * @param primary primary address
	 * @param subAccountId sub-account id whose address needs to be computed
	 */
	function getSubAccountAddress(address primary, uint256 subAccountId)
		public
		pure
		returns (address)
	{
		require(subAccountId < 256, "sub-account-id-too-big");
		return address(uint160(primary) ^ uint160(subAccountId));
	}

	struct ImportInputData {
		address[] _supplyTokens;
		address[] _borrowTokens;
		bool[] _enterMarket;
	}

	struct ImportData {
		address[] supplyTokens;
		address[] borrowTokens;
		EulerTokenInterface[] eTokens;
		EulerTokenInterface[] dTokens;
		uint256[] supplyAmts;
		uint256[] borrowAmts;
	}

	struct ImportHelper {
		uint256 supplylength;
		uint256 borrowlength;
		uint256 totalExecutions;
		address sourceAccount;
		address targetAccount;
	}

	function getSupplyAmounts(
		address userAccount, // user's EOA sub-account address
		ImportInputData memory inputData,
		ImportData memory data
	) internal view returns (ImportData memory) {
		data.supplyAmts = new uint256[](inputData._supplyTokens.length);
		data.supplyTokens = new address[](inputData._supplyTokens.length);
		data.eTokens = new EulerTokenInterface[](
			inputData._supplyTokens.length
		);
		uint256 length_ = inputData._supplyTokens.length;

		for (uint256 i = 0; i < length_; i++) {
			address token_ = inputData._supplyTokens[i] == ethAddr
				? wethAddr
				: inputData._supplyTokens[i];
			data.supplyTokens[i] = token_;
			data.eTokens[i] = EulerTokenInterface(
				markets.underlyingToEToken(token_)
			);
			data.supplyAmts[i] = data.eTokens[i].balanceOf(userAccount); //All 18 dec
		}

		return data;
	}

	function getBorrowAmounts(
		address userAccount, // user's EOA sub-account address
		ImportInputData memory inputData,
		ImportData memory data
	) internal view returns (ImportData memory) {
		uint256 borrowTokensLength_ = inputData._borrowTokens.length;

		if (borrowTokensLength_ > 0) {
			data.borrowTokens = new address[](borrowTokensLength_);
			data.dTokens = new EulerTokenInterface[](borrowTokensLength_);
			data.borrowAmts = new uint256[](borrowTokensLength_);

			for (uint256 i = 0; i < borrowTokensLength_; i++) {
				address _token = inputData._borrowTokens[i] == ethAddr
					? wethAddr
					: inputData._borrowTokens[i];

				data.borrowTokens[i] = _token;
				data.dTokens[i] = EulerTokenInterface(
					markets.underlyingToDToken(_token)
				);
				data.borrowAmts[i] = data.dTokens[i].balanceOf(userAccount);
			}
		}
		return data;
	}
}
