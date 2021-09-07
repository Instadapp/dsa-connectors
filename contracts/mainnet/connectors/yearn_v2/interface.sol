pragma solidity ^0.7.0;

interface YearnV2Interface {
    function deposit(uint256 amount, address recipient) external returns (uint256);
    
    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function token() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);
}

