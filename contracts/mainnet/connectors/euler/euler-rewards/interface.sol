//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IEulerDistributor {
    function claim(address account, address token, uint claimable, bytes32[] calldata proof, address stake) external;
}
