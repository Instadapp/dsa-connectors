//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IInstaLite {

	function supplyEth(address to_) external payable returns (uint256);

	function supply(
		address token_,
		uint256 amount_,
		address to_
	) external returns (uint256);

	function withdraw(uint256 amount_, address to_) external returns (uint256);

	function deleverage(uint amt_) external;
	function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external;
	function token() external returns(address);

}
