pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        address indexed token,
        address qiToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogWithdraw(
        address indexed token,
        address qiToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogBorrow(
        address indexed token,
        address qiToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogPayback(
        address indexed token,
        address qiToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogDepositQiToken(
        address indexed token,
        address qiToken,
        uint256 tokenAmt,
        uint256 qiTokenAmt,
        uint256 getId, 
        uint256 setId
    );

    event LogWithdrawQiToken(
        address indexed token,
        address qiToken,
        uint256 tokenAmt,
        uint256 qiTokenAmt,
        uint256 getId,
        uint256 setId
    );
    
    event LogLiquidate(
        address indexed borrower,
        address indexed tokenToPay,
        address indexed tokenInReturn,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );
}
