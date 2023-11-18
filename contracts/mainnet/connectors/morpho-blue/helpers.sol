//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interface.sol";
import "../../common/stores.sol";
import "../../common/basic.sol";
import "../../common/interfaces.sol";

abstract contract Helpers is Stores, Basic {
	
	IMorpho public constant MORPHO_BLUE =
		IMorpho(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);



	function _performEthToWethConversion(
		address _tokenAddress,
		uint256 _amount,
		uint256 _getId
	) internal returns (TokenInterface _tokenContract, uint256 _amt, bool _isMax) {
		_amt = getUint(_getId, _amount);
		_isMax = _amt == uint256(-1);

		if (_tokenAddress == ethAddr) {
		        _tokenContract = TokenInterface(wethAddr);
		        if (_amt == uint256(-1)) _amt = address(this).balance;
		        convertEthToWeth(true, _tokenContract, _amt);
		} else {
		       _tokenContract = TokenInterface(_tokenAddress);
		        if (_amt == uint256(-1)) _amt = _tokenContract.balanceOf(address(this)); 
		}
	}

    uint256 internal constant MARKET_PARAMS_BYTES_LENGTH = 5 * 32;

	/// @dev A number of virtual assets of 1 enforces a conversion rate between shares and assets when a market is
    /// empty.
	uint256 internal constant VIRTUAL_ASSETS = 1;

	/// @dev The number of virtual shares has been chosen low enough to prevent overflows, and high enough to ensure
    /// high precision computations.
    uint256 internal constant VIRTUAL_SHARES = 1e6;

    /// @notice Returns the id of the market `marketParams`.
    function id(MarketParams memory marketParams) internal pure returns (bytes32 marketParamsId) {
        assembly {
            marketParamsId := keccak256(marketParams, MARKET_PARAMS_BYTES_LENGTH)
        }
    }

	/// @dev Calculates the value of `shares` quoted in assets, rounding up.
    function _toAssetsUp(uint256 _shares, uint256 _totalAssets, uint256 _totalShares) internal pure returns (uint256) {
        return _mulDivUp(_shares, _totalAssets + VIRTUAL_ASSETS, _totalShares + VIRTUAL_SHARES);
    }

	/// @dev Returns (`x` * `y`) / `d` rounded up.
    function _mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
        return (x * y + (d - 1)) / d;
    }

	function _getApproveAmount(bytes32 _id, uint256 _assets, uint256 _shares) internal view returns (uint256 _amount) {
		_amount == 0 ? _assets = _toAssetsUp(_shares, MORPHO_BLUE.market(_id).totalSupplyAssets, MORPHO_BLUE.market(_id).totalSupplyShares) : _assets;
	}
}
