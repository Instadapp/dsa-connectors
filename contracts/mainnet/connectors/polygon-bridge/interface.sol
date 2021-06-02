pragma solidity ^0.7.0;

interface RootChainManagerInterface {
    function depositEtherFor(address user) external payable;
    function rootToChildToken(address user) external view returns(address);
    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;
    function exit(bytes calldata inputData) external;
}

interface DepositManagerProxyInterface {
    function depositERC20ForUser(
        address _token,
        address _user,
        uint256 _amount
    ) external;
}