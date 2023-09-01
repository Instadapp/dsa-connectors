// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./events.sol";
import "./interface.sol";

contract ApproveTokensResolver is Events {
    using SafeERC20 for IERC20;

    IAvoFactoryMultisig public constant AVO_FACTORY = IAvoFactoryMultisig(0xe981E50c7c47F0Df8826B5ce3F533f5E4440e687);

    function approveTokens(
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint32 index
    ) public returns (string memory _eventName, bytes memory _eventParam) {
        require(tokens.length == amounts.length, "array-length-mismatch");

        address avocadoAddress = AVO_FACTORY.computeAvocado(msg.sender, index);

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 allowanceAmount =
                amounts[i] == type(uint256).max
                    ? IERC20(tokens[i]).balanceOf(address(this))
                    : amounts[i];
            IERC20(tokens[i]).safeApprove(avocadoAddress, allowanceAmount);
        }

        _eventName = "LogApproveTokensMultisig(address[],uint256[],uint32)";
        _eventParam = abi.encode(tokens, amounts, index);
    }
}

contract ConnectV2ApproveTokensMultisigAvalanche is ApproveTokensResolver {
    string constant public name = "ApproveTokens-v1";
}