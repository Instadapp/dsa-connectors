pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogWithdraw(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogBorrow(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogPayback(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    event LogDepositCToken(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 cTokenAmt,
        uint256 getId, 
        uint256 setId
    );

    event LogWithdrawCToken(
        address indexed token,
        address cToken,
        uint256 tokenAmt,
        uint256 cTokenAmt,
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

    event LogBuyTokens(
        address indexed buyer, 
        uint256 underlyingIn, 
        uint256 tokensOut, 
        uint256 fee
    );
    
    event LogSellTokens(
        address indexed seller, 
        uint256 tokensIn, 
        uint256 underlyingOut, 
        uint256 forfeits
    );

    event LogBuySeniorBond(
        address indexed buyer, 
        uint256 indexed seniorBondId, 
        uint256 underlyingIn, 
        uint256 gain, 
        uint256 forDays
    );

    event LogRedeemSeniorBond(
        address indexed owner, 
        uint256 indexed seniorBondId, 
        uint256 fee
    );

    event LogBuyJuniorBond(
        address indexed buyer, 
        uint256 indexed juniorBondId, 
        uint256 tokensIn, 
        uint256 maturesAt
    );

    event LogRedeemJuniorBond(
        address indexed owner, 
        uint256 indexed juniorBondId, 
        uint256 underlyingOut
    );
}
