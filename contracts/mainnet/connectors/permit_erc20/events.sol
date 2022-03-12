pragma solidity ^0.7.0;

contract Events {
    event depositWithPermit(
        address asset,
        address owner, 
        uint256 nonce, 
        uint256 amount, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    );
}