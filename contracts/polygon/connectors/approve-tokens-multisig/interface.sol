// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IAvoFactoryMultisig {
    function computeAvocado(address owner_, uint32 index_) external view returns (address computedAddress_);
}