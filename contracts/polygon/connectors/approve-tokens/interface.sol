// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IAvoFactory {
    function computeAddress(address owner_) external view returns (address);
}