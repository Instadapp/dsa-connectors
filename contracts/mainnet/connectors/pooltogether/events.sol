pragma solidity ^0.7.0;

import { TokenFaucetInterface } from "./interface.sol";

contract Events {
    event LogDepositTo(address prizePool, address to, uint256 amount, address controlledToken, uint256 getId, uint256 setId);
    event LogWithdrawInstantlyFrom(address prizePool, address from, uint256 amount, address controlledToken, uint256 maximumExitFee, uint256 exitFee, uint256 getId, uint256 setId);
    event LogClaim(address tokenFaucet, address user, uint256 claimed, uint256 setId);
    event LogClaimAll(address tokenFaucetProxyFactory, address user, TokenFaucetInterface[] tokenFaucets);
    event LogClaimPodTokenDrop(address podTokenDrop, address user, uint256 claimed, uint256 setId);
    event LogDepositToPod(address prizePoolToken, address pod, address to, uint256 amount, uint256 podShare, uint256 getId, uint256 setId);
    event LogWithdrawFromPod(address pod, uint256 shareAmount, uint256 tokenAmount, uint256 maxFee, uint256 getId, uint256 setId);
}