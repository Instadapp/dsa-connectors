pragma solidity ^0.7.0;

contract Events {
    event LogDepositERC721(
        address indexed erc721,
        address from,
        uint256 tokenId
    );
    event LogWithdrawERC721(
        address indexed erc721,
        uint256 tokenId,
        address indexed to
    );
}
