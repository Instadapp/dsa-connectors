//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./interface.sol";
import "../../common/stores.sol";
import "../../common/basic.sol";
import "../../common/interfaces.sol";

abstract contract Helpers is Stores, Basic {
	IMorphoCore public constant MORPHO_AAVE_V3 =
		IMorphoCore(0x33333aea097c193e66081E930c33020272b33333);
	
	uint256 public max_iteration = 4;

	function _performEthToWethConversion(
		address _tokenAddress,
		uint256 _amount,
		uint256 _getId
	) internal returns (TokenInterface _tokenContract, uint256 _amt) {
		_amt = getUint(_getId, _amount);

		if (_tokenAddress == ethAddr) {
		        _tokenContract = TokenInterface(wethAddr);
		        if (_amt == type(uint256).max) _amt = address(this).balance;
		        convertEthToWeth(true, _tokenContract, _amt);
		} else {
		       _tokenContract = TokenInterface(_tokenAddress);
		        if (_amt == type(uint256).max) _amt = _tokenContract.balanceOf(address(this)); 
		}
	}
}
