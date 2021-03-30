pragma solidity ^0.7.0;

contract Events {
    event LogOpen(uint256 indexed safe, bytes32 indexed collateralType);
    event LogClose(uint256 indexed safe, bytes32 indexed collateralType);
    event LogTransfer(uint256 indexed safe, bytes32 indexed collateralType, address newOwner);
    event LogDeposit(uint256 indexed safe, bytes32 indexed collateralType, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdraw(uint256 indexed safe, bytes32 indexed collateralType, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogBorrow(uint256 indexed safe, bytes32 indexed collateralType, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogPayback(uint256 indexed safe, bytes32 indexed collateralType, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdrawLiquidated(uint256 indexed safe, bytes32 indexed collateralType, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogExit(uint256 indexed safe, bytes32 indexed collateralType, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogDepositAndBorrow(
        uint256 indexed safe,
        bytes32 indexed collateralType,
        uint256 depositAmt,
        uint256 borrowAmt,
        uint256 getIdDeposit,
        uint256 getIdBorrow,
        uint256 setIdDeposit,
        uint256 setIdBorrow
    );
}
