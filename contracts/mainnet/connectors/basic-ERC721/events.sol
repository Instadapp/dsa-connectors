pragma solidity ^0.7.0;

contract Events {
    event LogDepositERC721(
        address indexed erc721,
        address from,
        uint256 tokenId,
        uint256 getId,
        uint256 setId
    );
    event LogWithdrawERC721(
        address indexed erc721,
        uint256 tokenId,
        address indexed to,
        uint256 getId,
        uint256 setId
    );
}
