pragma solidity ^0.7.0;

interface erc20StablecoinInterface {

    function createVault() external returns (uint256);
    function destroyVault(uint256 vaultID) external;
    function depositCollateral(uint256 vaultID, uint256 amount) external;
    function withdrawCollateral(uint256 vaultID, uint256 amount) external;
    function borrowToken(uint256 vaultID, uint256 amount) external;
    function payBackToken(uint256 vaultID, uint256 amount) external;
    function transferVault(uint256 vaultID, address to) external;
    function vaultOwner(uint256 vaultID) external returns (address);
}

interface maticStablecoinInterface is erc20StablecoinInterface {
    function depositCollateral(uint256 vaultID) external payable;
}

interface camTokenInterface {
    function balanceOf(address _user) external view returns(uint256);
}
