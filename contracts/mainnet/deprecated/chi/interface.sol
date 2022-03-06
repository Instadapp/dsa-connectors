//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface CHIInterface {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint256) external;
}
