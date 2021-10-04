pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface ListInterface {
    struct AccountLink {
        address first;
        address last;
        uint64 count;
    }

    function accountID(address) external view returns (uint64);
    function accountLink(uint64) external view returns (AccountLink memory);
}