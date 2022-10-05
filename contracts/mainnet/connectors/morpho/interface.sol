//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IMorphoCore {
    function supply(
        address _poolTokenAddress,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;

    function borrow(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;

    function withdraw(
        address _poolTokenAddress,
        uint256 _amount
    ) external;

    function repay(
        address _poolTokenAddress,
        address _onBehalf,
        uint256 _amount
    ) external;

    function liquidate(
        address _poolTokenBorrowedAddress, 
        address _poolTokenCollateralAddress,
        address _borrower,
        uint256 _amount
    ) external;

    // (For AAVEV2: (aToken or variable debt token), COMPOUNDV2: cToken addresses)
    function claimRewards(
        address[] _tokenAddresses,
        bool _tradeForMorphoToken,
    ) external;
}