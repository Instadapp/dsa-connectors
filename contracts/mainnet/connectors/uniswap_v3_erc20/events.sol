pragma solidity ^0.7.0;

contract Events {

    event LogDepositLiquidity(
        address indexed pool,
        uint256 amtA,
        uint256 amtB,
        uint256 uniAmount,
        uint256 getId,
        uint256 setId
    );

    event LogWithdrawLiquidity(
        address indexed pool,
        uint256 amountA,
        uint256 amountB,
        uint256 uniAmount,
        uint256 getId,
        uint256 setId
    );

}