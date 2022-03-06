//SPDX-License-Identifier: MIT
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

struct UserInfo {
	uint256 amount;
	uint256 rewardDebt;
}

struct PoolInfo {
	IERC20 lpToken; // Address of LP token contract.
	uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
	uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
	uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
}

interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);

	/// @notice EIP 2612
	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}

interface IMasterChef {
	function poolLength() external view returns (uint256);

	function updatePool(uint256 pid) external returns (PoolInfo memory);

	function poolInfo(uint256 pid)
		external
		view
		returns (
			address,
			uint256,
			uint256,
			uint256
		);

	function userInfo(uint256 _pid, address _user)
		external
		view
		returns (uint256, uint256);

	function deposit(uint256 pid, uint256 amount) external;

	function withdraw(uint256 pid, uint256 amount) external;

	function emergencyWithdraw(uint256 pid, address to) external;
}

interface IMasterChefV2 {
	function poolLength() external view returns (uint256);

	function updatePool(uint256 pid) external returns (PoolInfo memory);

	function lpToken(uint256 pid) external view returns (address);

	function userInfo(uint256 _pid, address _user)
		external
		view
		returns (uint256, uint256);

	function deposit(
		uint256 pid,
		uint256 amount,
		address to
	) external;

	function withdraw(
		uint256 pid,
		uint256 amount,
		address to
	) external;

	function emergencyWithdraw(uint256 pid, address to) external;

	function harvest(uint256 pid, address to) external;

	function withdrawAndHarvest(
		uint256 pid,
		uint256 amount,
		address to
	) external;
}

interface ISushiSwapFactory {
	function getPair(address tokenA, address tokenB)
		external
		view
		returns (address pair);

	function allPairs(uint256) external view returns (address pair);

	function allPairsLength() external view returns (uint256);

	function feeTo() external view returns (address);

	function feeToSetter() external view returns (address);

	function createPair(address tokenA, address tokenB)
		external
		returns (address pair);
}
