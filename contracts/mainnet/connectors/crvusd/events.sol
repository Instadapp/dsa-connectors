//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
    event LogCreateLoan(address indexed collateral, uint256 amt, uint256 debt, uint256 indexed numBands, uint256 controllerVersion, uint256 getId, uint256 setId);
    event LogAddCollateral(address indexed collateral, uint256 indexed amt, uint256 controllerVersion, uint256 getId, uint256 setId);
    event LogRemoveCollateral(address indexed collateral, uint256 indexed amt, uint256 getId, uint256 setId);
    event LogBorrowMore(address indexed collateral, uint256 indexed amt, uint256 controllerVersion, uint256 indexed debt);
    event LogRepay(address indexed collateral, uint256 indexed amt, uint256 controllerVersion, uint256 getId, uint256 setId);
    event LogLiquidate(address indexed collateral, uint256 indexed min_x, uint256 controllerVersion, uint256 getId, uint256 setId);
}