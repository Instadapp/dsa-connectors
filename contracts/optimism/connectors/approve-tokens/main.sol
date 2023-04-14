// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./events.sol";
import "./interface.sol";

contract ApproveTokensResolver is Events {
    using SafeERC20 for IERC20;

    IAvoFactory public constant AVO_FACTORY = IAvoFactory(0x3AdAE9699029AB2953F607AE1f62372681D35978);

    function approveTokens(
        address[] calldata tokens,
        uint256[] calldata amounts
    ) public returns (string memory _eventName, bytes memory _eventParam) {
        require(tokens.length == amounts.length, "array-length-mismatch");

        address avocadoAddress = AVO_FACTORY.computeAddress(msg.sender);

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 allowanceAmount =
                amounts[i] == type(uint256).max
                    ? IERC20(tokens[i]).balanceOf(address(this))
                    : amounts[i];
            IERC20(tokens[i]).safeApprove(avocadoAddress, allowanceAmount);
        }

        _eventName = "LogApproveTokens(address[],uint256[])";
        _eventParam = abi.encode(tokens, amounts);
    }
}

contract ConnectV2ApproveTokensOptimism is ApproveTokensResolver {
    string constant public name = "ApproveTokens-v1";
}