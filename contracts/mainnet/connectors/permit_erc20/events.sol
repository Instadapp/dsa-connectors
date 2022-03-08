pragma solidity ^0.7.0;

contract Events {
    event depositWithPermit(
        address _asset,
        address _owner, 
        uint256 nonce, 
        uint256 _amount, 
        uint256 _deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    );
}