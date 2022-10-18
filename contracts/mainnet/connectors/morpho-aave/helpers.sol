//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./interface.sol";
import "../../common/stores.sol";
import "../../common/basic.sol";
import "../../common/interfaces.sol";

abstract contract Helpers is Stores, Basic {
	IMorphoCore public constant MORPHO_AAVE =
		IMorphoCore(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);

	IMorphoAaveLens public constant MORPHO_AAVE_LENS =
		IMorphoAaveLens(0x507fA343d0A90786d86C7cd885f5C49263A91FF4);

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
