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
    IEulerExecute internal constant eulerExec = IEulerExecute(0x59828FdF7ee634AaaD3f58B19fDBa3b03E2D9d80);

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
		address[] supplyTokens;
		address[] borrowTokens;
		bool[] enterMarket;
	}

    struct ImportData {
		address[] _supplyTokens;
		address[] _borrowTokens;
		EulerTokenInterface[] eTokens;
        EulerTokenInterface[] dTokens;
		uint256[] supplyAmts;
		uint256[] borrowAmts;
	}

    function getSupplyAmounts(
		address userAccount,//user's EOA sub-account address
		ImportInputData memory inputData,
		ImportData memory data
	) internal view returns (ImportData memory) {
		data.supplyAmts = new uint256[](inputData.supplyTokens.length);
		data._supplyTokens = new address[](inputData.supplyTokens.length);
		data.eTokens = new EulerTokenInterface[](inputData.supplyTokens.length);

		for (uint256 i = 0; i < inputData.supplyTokens.length; i++) {
			for (uint256 j = i; j < inputData.supplyTokens.length; j++) {
				if (j != i) {
					require(
						inputData.supplyTokens[i] != inputData.supplyTokens[j],
						"token-repeated"
					);
				}
			}
		}
		for (uint256 i = 0; i < inputData.supplyTokens.length; i++) {
			address _token = inputData.supplyTokens[i] == ethAddr
				? wethAddr
				: inputData.supplyTokens[i];
			data._supplyTokens[i] = _token;
			data.eTokens[i] = EulerTokenInterface(markets.underlyingToEToken(_token));
			data.supplyAmts[i] = data.eTokens[i].balanceOf(userAccount);//All 18 dec
		}

		return data;
	}

    function getBorrowAmounts(
		address userAccount,//user's EOA sub-account address
		ImportInputData memory inputData,
		ImportData memory data
	) internal view returns (ImportData memory) {
		uint _borrowTokensLength = inputData.borrowTokens.length;

		if (_borrowTokensLength > 0) {
			data._borrowTokens = new address[](_borrowTokensLength);
			data.dTokens = new EulerTokenInterface[](_borrowTokensLength);
			data.borrowAmts = new uint256[](_borrowTokensLength);
			for (uint256 i = 0; i < _borrowTokensLength; i++) {
				for (uint256 j = i; j < _borrowTokensLength; j++) {
					if (j != i) {
						require(
							inputData.borrowTokens[i] !=
								inputData.borrowTokens[j],
							"token-repeated"
						);
					}
				}
			}

			for (uint256 i = 0; i < _borrowTokensLength; i++) {
				address _token = inputData.borrowTokens[i] == ethAddr
					? wethAddr
					: inputData.borrowTokens[i];

				data._borrowTokens[i] = _token;
                data.dTokens[i] = EulerTokenInterface(markets.underlyingToDToken(_token));
                data.borrowAmts[i] = data.dTokens[i].balanceOf(userAccount);
			}
		}
		return data;
	}
}
