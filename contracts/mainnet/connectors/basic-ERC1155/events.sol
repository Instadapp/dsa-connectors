pragma solidity ^0.7.0;

contract Events {
    event LogDepositERC1155(
        address indexed erc1155,
        address from,
        uint256 tokenId,
        uint256 amount,
        uint256 getId,
        uint256 setId
    );
    event LogWithdrawERC1155(
        address indexed erc1155,
        uint256 tokenId,
        address indexed to,
        uint256 amount,
        uint256 getId,
        uint256 setId
    );
}
