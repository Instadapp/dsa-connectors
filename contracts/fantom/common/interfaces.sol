pragma solidity ^0.7.0;

interface TokenInterface {
	function approve(address, uint256) external;

	function transfer(address, uint256) external;

	function transferFrom(
		address,
		address,
		uint256
	) external;

	function deposit() external payable;

	function withdraw(uint256) external;

	function balanceOf(address) external view returns (uint256);

	function decimals() external view returns (uint256);
}

interface MemoryInterface {
	function getUint(uint256 id) external returns (uint256 num);

	function setUint(uint256 id, uint256 val) external;
}

interface AccountInterface {
	function enable(address) external;

	function disable(address) external;

	function isAuth(address) external view returns (bool);
}
