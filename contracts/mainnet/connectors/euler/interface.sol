//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IEulerMarkets {
    function enterMarket(uint subAccountId, address newMarket) external;
    function getEnteredMarkets(address account) external view returns (address[] memory);
    function exitMarket(uint subAccountId, address oldMarket) external;
    function underlyingToEToken(address underlying) external view returns (address);
    function underlyingToDToken(address underlying) external view returns (address);
}

interface IEulerEToken {
    function deposit(uint subAccountId, uint amount) external;
    function withdraw(uint subAccountId, uint amount) external;
    function decimals() external view returns (uint8);
    function mint(uint subAccountId, uint amount) external;
    function burn(uint subAccountId, uint amount) external;
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
}

interface IEulerDToken {
    function underlyingToDToken(address underlying) external view returns (address);
    function decimals() external view returns (uint8);
    function borrow(uint subAccountId, uint amount) external;
    function repay(uint subAccountId, uint amount) external;
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
    function approveDebt(uint subAccountId, address spender, uint amount) external returns (bool);
}

interface IEulerSwap {
    struct Swap1InchParams {
        uint subAccountIdIn;
        uint subAccountIdOut;
        address underlyingIn;
        address underlyingOut;
        uint amount;
        uint amountOutMinimum;
        bytes payload;
    }

    function swap1Inch(Swap1InchParams memory) external;
}
