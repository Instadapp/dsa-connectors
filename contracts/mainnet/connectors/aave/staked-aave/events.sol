pragma solidity ^0.7.0;

contract Events {
    event LogClaim(uint amt, uint getId, uint setId);
    event LogStake(uint amt, uint getId, uint setId);
    event LogCooldown();
    event LogRedeem(uint amt, uint getId, uint setId);
    event LogDelegate(
        address delegatee,
        bool delegateAave,
        bool delegateStkAave,
        uint8 aaveDelegationType,
        uint8 stkAaveDelegationType
    );
}