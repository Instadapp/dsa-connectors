pragma solidity ^0.7.0;

contract Events {

    event LogDepositLiquidity(
        address indexed pool,
        uint256 amtA,
        uint256 amtB,
        uint256 mintAmount,
        uint256[] getIds,
        uint256 setId
    );

    event LogWithdrawLiquidity(
        address indexed pool,
        uint256 amountA,
        uint256 amountB,
        uint256 burnAmount,
        uint256 getId,
        uint256[] setIds
    );

    event LogSwapAndDepositLiquidity(
        address indexed pool,
        uint256 amtA,
        uint256 amtB,
        uint256 mintAmount,
        bool zeroForOne,
        uint swapAmount,
        uint256 getId,
        uint256 setId
    );

}