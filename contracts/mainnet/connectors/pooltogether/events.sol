pragma solidity ^0.7.0;

import { TokenFaucetInterface } from "./interface.sol";

contract Events {
    event LogDepositTo(address prizePool, address to, uint256 amount, address controlledToken, address referrer, uint256 getId, uint256 setId);
    event LogWithdrawInstantlyFrom(address prizePool, address from, uint256 amount, address controlledToken, uint256 maximumExitFee, uint256 getId, uint256 setId);
    event LogClaim(address tokenFaucet, address user);
    event LogClaimAll(address tokenFaucetProxyFactory, address user, TokenFaucetInterface[] tokenFaucets);
}