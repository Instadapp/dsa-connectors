pragma solidity ^0.7.0;

contract Events {
    event LogDepositLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amtA,
        uint256 amtB,
        uint256 uniAmount,
        uint256 getId,
        uint256 setId
    );

    event LogWithdrawLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 uniAmount,
        uint256 getId,
        uint256[] setId
    );
    
    event LogBuy(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    event LogSell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );
}