pragma solidity ^0.7.0;

/**
 * @title Basic.
 * @dev Deposit & Withdraw from DSA.
 */
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {Events} from "./events.sol";

abstract contract BasicResolver is Events, DSMath, Basic {
    /**
     * @dev Deposit Assets To Smart Account.
     * @notice Deposit a ERC721 token to DSA
     * @param token The address of the token to deposit.
     * @param tokenId The id of token to deposit.
     */
    function depositERC721(address token, uint256 tokenId)
        public
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        IERC721 tokenContract = IERC721(token);
        tokenContract.safeTransferFrom(msg.sender, address(this), tokenId);

        _eventName = "LogDepositERC721(address,address,uint256)";
        _eventParam = abi.encode(token, msg.sender, tokenId);
    }

    /**
     * @dev Withdraw Assets To Smart Account.
     * @notice Withdraw a ERC721 token from DSA
     * @param token The address of the token to deposit.
     * @param tokenId The id of token to deposit.
     * @param to The address to receive the token upon withdrawal
     */
    function withdrawERC721(
        address token,
        uint256 tokenId,
        address payable to
    )
        public
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        IERC721 tokenContract = IERC721(token);
        tokenContract.safeTransferFrom(address(this), to, tokenId);

        _eventName = "LogWithdrawERC721(address,uint256,address)";
        _eventParam = abi.encode(token, tokenId, to);
    }
}

contract ConnectV2Basic is BasicResolver {
    string public constant name = "BASIC-ERC721-A";
}
