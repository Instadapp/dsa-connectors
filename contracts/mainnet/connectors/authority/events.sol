pragma solidity ^0.7.0;

contract Events {
    event LogAddAuth(address indexed _msgSender, address indexed _authority);
    event LogRemoveAuth(address indexed _msgSender, address indexed _authority);
}