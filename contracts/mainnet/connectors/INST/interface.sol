pragma solidity ^0.7.0;

interface InstaGovernorInterface {
    function castVoteWithReason(uint proposalId, uint8 support, string calldata reason) external;
}

interface InstaTokenInterface {
    function delegate(address delegatee) external;
    function delegates(address) external view returns(address);
}