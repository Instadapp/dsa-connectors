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
     * @param token The address of the token to deposit.
     * @param tokenId The id of token to deposit.
     * @param to The address to receive the token upon withdrawal
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

contract ConnectV2Basic is BasicResolver {
    string public constant name = "BASIC-ERC721-A";
}
