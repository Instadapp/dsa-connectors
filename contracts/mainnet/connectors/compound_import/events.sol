pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
    event LogCompoundImport(
        address indexed user,
        address[] ctokens,
        string[] supplyIds,
        string[] borrowIds,
        uint[] supplyAmts,
        uint[] borrowAmts
    );
}