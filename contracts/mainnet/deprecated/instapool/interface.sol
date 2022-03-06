//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface LiqudityInterface {
    function deposit(address, uint) external payable;
    function withdraw(address, uint) external;

    function accessLiquidity(address[] calldata, uint[] calldata) external;
    function returnLiquidity(address[] calldata) external payable;

    function isTknAllowed(address) external view returns(bool);
    function tknToCTkn(address) external view returns(address);
    function liquidityBalance(address, address) external view returns(uint);

    function borrowedToken(address) external view returns(uint);
}

interface InstaPoolFeeInterface {
    function fee() external view returns(uint);
    function feeCollector() external view returns(address);
}

interface CTokenInterface {
    function borrowBalanceCurrent(address account) external returns (uint);
    function balanceOf(address owner) external view returns (uint256 balance);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint); // For ERC20
}

interface CETHInterface {
    function borrowBalanceCurrent(address account) external returns (uint);
    function repayBorrowBehalf(address borrower) external payable;
}
