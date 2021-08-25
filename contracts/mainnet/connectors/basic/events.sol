pragma solidity ^0.7.0;

contract Events {
    event LogDeposit(
        address indexed erc20,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );
    event LogWithdraw(
        address indexed erc20,
        uint256 tokenAmt,
        address indexed to,
        uint256 getId,
        uint256 setId
    );
    event LogDepositERC721(address indexed erc721, uint256 tokenId);
    event LogWithdrawERC721(
        address indexed erc721,
        uint256 tokenId,
        address indexed to
    );
}
