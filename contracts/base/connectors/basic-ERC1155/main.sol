//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title Basic.
 * @dev Deposit & Withdraw from ERC1155 DSA.
 */
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {Events} from "./events.sol";

abstract contract BasicResolver is Events, DSMath, Basic {
    /**
     * @dev Deposit Assets To Smart Account.
     * @notice Deposit a ERC1155 token to DSA
     * @param token Address of token.
     * @param tokenId ID of token.
     * @param amount Amount to deposit.
     * @param getId ID to retrieve amount.
     * @param setId ID stores the amount.
     */
    function depositERC1155(
        address token,
        uint256 tokenId,
        uint256 amount,
        uint256 getId,
        uint256 setId
    )
        public
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amount = getUint(getId, amount);

        IERC1155 tokenContract = IERC1155(token);
        tokenContract.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            _amount,
            ""
        );

        setUint(setId, _amount);

        _eventName = "LogDepositERC1155(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            token,
            msg.sender,
            tokenId,
            _amount,
            getId,
            setId
        );
    }

    /**
     * @dev Withdraw Assets To Smart Account.
     * @notice Withdraw a ERC1155 token from DSA
     * @param token Address of the token.
     * @param tokenId ID of token.
     * @param to The address to receive the token upon withdrawal
     * @param amount Amount to withdraw.
     * @param getId ID to retrieve amount.
     * @param setId ID stores the amount.
     */
    function withdrawERC1155(
        address token,
        uint256 tokenId,
        address payable to,
        uint256 amount,
        uint256 getId,
        uint256 setId
    )
        public
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amount = getUint(getId, amount);
        IERC1155 tokenContract = IERC1155(token);
        tokenContract.safeTransferFrom(address(this), to, tokenId, _amount, "");

        setUint(setId, _amount);

        _eventName = "LogWithdrawERC1155(address,uint256,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, tokenId, to, _amount, getId, setId);
    }
}

contract ConnectV2BasicERC1155Base is BasicResolver {
    string public constant name = "BASIC-ERC1155-v1.0";
}
