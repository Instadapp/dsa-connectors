pragma solidity >=0.6.2;
pragma abicoder v2;

import { TokenInterface } from "../../../common/interfaces.sol";

interface IERC20 is TokenInterface{

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IStakingRewards {
    // Storage
    function rewards(address account) view external returns (uint256);

    // View
    function balanceOf(address account) external view returns (uint256);
    function rewardsToken() external view returns (address);

    // Mutative
    function exit() external;
    function getReward() external;
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
}

interface IMiniChefV2 {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    // Storage
    function addedTokens(address token) external returns (bool);
    function lpToken(uint256 _pid) external view returns (IERC20);
    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

    // View
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
    function poolLength() external view returns (uint256);

    // Mutative
    function deposit(uint256 pid, uint256 amount, address to) external;
    function depositWithPermit(uint256 pid, uint256 amount, address to, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
}