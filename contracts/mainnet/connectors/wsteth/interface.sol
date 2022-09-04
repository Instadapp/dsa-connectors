//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IWSTETH {
    function balanceOf(address account) external view returns (uint256);
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
}
