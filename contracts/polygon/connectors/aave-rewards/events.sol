pragma solidity ^0.7.0;

contract Events {
    event LogClaimed(
        address[] assets,
        uint256 amt,
        bool stake,
        uint256 getId,
        uint256 setId
    );
}
