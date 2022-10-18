//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./interface.sol";
import "../../common/stores.sol";
import "../../common/basic.sol";
import "../../common/interfaces.sol";

abstract contract Helpers is Stores, Basic {
	IMorphoCore public constant MORPHO_COMPOUND =
		IMorphoCore(0x8888882f8f843896699869179fB6E4f7e3B58888);

	IMorphoCompoundLens public constant MORPHO_COMPOUND_LENS =
		IMorphoCompoundLens(0x930f1b46e1D081Ec1524efD95752bE3eCe51EF67);

	function _performEthToWethConversion(
		address _tokenAddress,
		uint256 _amount,
		uint256 _getId
	) internal returns (TokenInterface _tokenContract, uint256 _amt) {
		_amt = getUint(_getId, _amount);

		if (_tokenAddress == ethAddr) {
		        _tokenContract = TokenInterface(wethAddr);
		        if (_amt == uint256(-1)) _amt = address(this).balance;
		        convertEthToWeth(true, _tokenContract, _amt);
		} else {
		       _tokenContract = TokenInterface(_tokenAddress);
		        if (_amt == uint256(-1)) _amt = _tokenContract.balanceOf(address(this)); 
		}
	}
}
