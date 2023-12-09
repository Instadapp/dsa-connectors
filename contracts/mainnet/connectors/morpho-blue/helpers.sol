//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interface.sol";
import "../../common/stores.sol";
import "../../common/basic.sol";
import "../../common/interfaces.sol";

abstract contract Helpers is Stores, Basic {
	
	IMorpho public constant MORPHO_BLUE =
		IMorpho(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0); // TODO: Update

	uint256 internal constant MARKET_PARAMS_BYTES_LENGTH = 5 * 32;

	/// @dev The number of virtual assets of 1 enforces a conversion rate between shares and assets when a market is
    /// empty.
	uint256 internal constant VIRTUAL_ASSETS = 1;

	/// @dev The number of virtual shares has been chosen low enough to prevent overflows, and high enough to ensure
    /// high precision computations.
    uint256 internal constant VIRTUAL_SHARES = 1e6;

	/// @notice Handles Eth to Weth conversion if assets are provided.
	function _performEthToWethConversion(
		MarketParams memory _marketParams,
		uint256 _assets,
		address _onBehalf,
		uint256 _getId,
		bool _isCollateral,
		bool _isRepay
	) internal returns (TokenInterface _tokenContract, uint256 _amt) {
		_amt = getUint(_getId, _assets);
		bool _isEth = _isCollateral ? _marketParams.collateralToken == ethAddr : _marketParams.loanToken == ethAddr;

		// Set the correct token contract
		_tokenContract = _isEth ? TokenInterface(wethAddr) : TokenInterface(_marketParams.loanToken);

		// Check for max value
		if (_assets == type(uint256).max) {
			uint256 _maxAvailable = _isEth ? address(this).balance : _tokenContract.balanceOf(address(this));
			if (_isRepay) {
				uint256 _amtDebt = getPaybackBalance(_marketParams, _onBehalf);
				_amt = min(_maxAvailable, _amtDebt);
			} else {
				_amt = _maxAvailable;
			}
		}

		// Perform conversion if necessary
		if (_isEth) {
			convertEthToWeth(true, _tokenContract, _amt);
		}
	}

	/// @notice Handles Eth to Weth conversion if shares are provided.
	function _performEthToWethSharesConversion(
		MarketParams memory _marketParams,
		uint256 _shares,
		address _onBehalf,
		uint256 _getId,
		bool _isRepay
	) internal returns (TokenInterface _tokenContract, uint256 _assets) {
		uint256 _shareAmt = getUint(_getId, _shares);
		bool _isEth = _marketParams.loanToken == ethAddr;

		// Set the token contract based on whether the loan token is ETH
		_tokenContract = _isEth ? TokenInterface(wethAddr) : TokenInterface(_marketParams.loanToken);

		// Handle the max share case or normal share conversion
		if (_isRepay && _shares == type(uint256).max) {
			uint256 _maxAvailable = _isEth ? address(this).balance : _tokenContract.balanceOf(address(this));
			_assets = min(_maxAvailable, getPaybackBalance(_marketParams, _onBehalf));
		} else {
			bytes32 _id = id(_marketParams);
			_assets = _toAssetsUp(_shareAmt, MORPHO_BLUE.market(_id).totalSupplyAssets, MORPHO_BLUE.market(_id).totalSupplyShares);
		}

		// Perform ETH to WETH conversion if necessary
		if (_isEth) {
			convertEthToWeth(true, _tokenContract, _assets);
		}
	}

	/// @notice Helper function to find the minimum of two values
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	/// @notice Returns the payback balance in assets.
	function getPaybackBalance(MarketParams memory _marketParams, address _onBehalf) internal view returns(uint256 _assets) {
		bytes32 _id = id(_marketParams);

		uint256 _shareAmt = MORPHO_BLUE.position(_id, _onBehalf).supplyShares;

		_assets =
			_toAssetsUp(
				_shareAmt,
				MORPHO_BLUE.market(_id).totalSupplyAssets,
				MORPHO_BLUE.market(_id).totalSupplyShares
			);

	}

    /// @notice Returns the id of the market `marketParams`.
    function id(MarketParams memory marketParams) internal pure returns (bytes32 marketParamsId) {
        assembly {
            marketParamsId := keccak256(marketParams, MARKET_PARAMS_BYTES_LENGTH)
        }
    }

	/// @notice Calculates the value of `shares` quoted in assets, rounding up.
    function _toAssetsUp(uint256 _shares, uint256 _totalAssets, uint256 _totalShares) internal pure returns (uint256) {
        return _mulDivUp(_shares, _totalAssets + VIRTUAL_ASSETS, _totalShares + VIRTUAL_SHARES);
    }

	/// @notice Returns (`x` * `y`) / `d` rounded up.
    function _mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
        return (x * y + (d - 1)) / d;
    }
}
