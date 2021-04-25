pragma solidity ^0.7.0;

import { TokenInterface } from "../../../common/interfaces.sol";

interface AaveInterface is TokenInterface {
    function delegate(address delegatee) external;
    function delegateByType(address delegatee, uint8 delegationType) external;
    function getDelegateeByType(address delegator, uint8 delegationType) external view returns (address);
}

interface StakedAaveInterface is AaveInterface {
    function stake(address onBehalfOf, uint256 amount) external;
    function redeem(address to, uint256 amount) external;
    function cooldown() external;
    function claimRewards(address to, uint256 amount) external;
}