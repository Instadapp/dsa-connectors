//SPDX-License-Identifier: MIT
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Basic.
 * @dev Deposit & Withdraw ERC721 from DSA.
 */
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {Events} from "./events.sol";

abstract contract BasicResolver is Events, DSMath, Basic {
    /**
     * @dev Deposit Assets To Smart Account.
     * @notice Deposit a ERC721 token to DSA
     * @param token Address of token.
     * @param tokenId ID of token.
     * @param getId ID to retrieve tokenId.
     * @param setId ID stores the tokenId.
     */
    function depositERC721(
        address token,
        uint256 tokenId,
        uint256 getId,
        uint256 setId
    )
        public
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _tokenId = getUint(getId, tokenId);

        IERC721 tokenContract = IERC721(token);
        tokenContract.safeTransferFrom(msg.sender, address(this), _tokenId);

        setUint(setId, _tokenId);

        _eventName = "LogDepositERC721(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, msg.sender, _tokenId, getId, setId);
    }

    /**
     * @dev Withdraw Assets To Smart Account.
     * @notice Withdraw a ERC721 token from DSA
     * @param token Address of the token.
     * @param tokenId ID of token.
     * @param to The address to receive the token upon withdrawal
     * @param getId ID to retrieve tokenId.
     * @param setId ID stores the tokenId.
     */
    function withdrawERC721(
        address token,
        uint256 tokenId,
        address payable to,
        uint256 getId,
        uint256 setId
    )
        public
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _tokenId = getUint(getId, tokenId);
        IERC721 tokenContract = IERC721(token);
        tokenContract.safeTransferFrom(address(this), to, _tokenId);

        setUint(setId, _tokenId);

        _eventName = "LogWithdrawERC721(address,uint256,address,uint256,uint256)";
        _eventParam = abi.encode(token, _tokenId, to, getId, setId);
    }
}

contract ConnectV2BasicERC721Avalanche is BasicResolver {
    string public constant name = "BASIC-ERC721-v1.0";
}
