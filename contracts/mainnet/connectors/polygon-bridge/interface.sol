pragma solidity ^0.7.0;

interface RootChainManagerInterface {
    function depositEtherFor(address user) external payable;
    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;
    function exit(bytes calldata inputData) external;
}