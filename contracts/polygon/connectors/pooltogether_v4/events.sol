pragma solidity ^0.7.0;

// import { TokenFaucetInterface } from "./interface.sol";

contract Events {
    event LogDepositTo(address prizePool, address to, uint256 amount, uint256 getId, uint256 setId);
    event LogDepositToDelegate(address prizePool, address to, uint256 amount, address delegate, uint256 getId, uint256 setId);
    event LogWithdrawFrom(address prizePool, address from, uint256 amount, uint256 getId, uint256 setId);
    event LogDelegated(address prizePool, address user, address to);
    event LogClaim(address prizeDistributor, address user, uint32[] drawIds, bytes data, uint256 payout, uint256 setId);
}