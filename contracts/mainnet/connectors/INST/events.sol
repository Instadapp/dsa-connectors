pragma solidity ^0.7.0;

contract Events {
    event LogVoteCast(uint256 proposalId, uint256 support, string reason);
    event LogDelegate(address delegatee);
}
