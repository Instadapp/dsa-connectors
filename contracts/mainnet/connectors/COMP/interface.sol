pragma solidity ^0.7.0;

interface ComptrollerInterface {
    function claimComp(address holder) external;
    function claimComp(address holder, address[] calldata) external;
    function claimComp(address[] calldata holders, address[] calldata cTokens, bool borrowers, bool suppliers) external;
}

interface COMPInterface {
    function delegate(address delegatee) external;
    function delegates(address) external view returns(address);
}
