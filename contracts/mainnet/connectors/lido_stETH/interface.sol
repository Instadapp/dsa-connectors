pragma solidity ^0.7.0;

interface ILido {
	function submit(address _referral) external payable returns (uint256);
}
