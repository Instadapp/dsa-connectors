// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./events.sol";
import "./interface.sol";

contract ApproveTokensResolver is Events {
    using SafeERC20 for IERC20;

    IAvoFactoryMultisig public constant AVO_FACTORY = IAvoFactoryMultisig(0x09389f927AE43F93958A4eBF2Bbb24B9fE88f6c5);

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

contract ConnectV2ApproveTokensMultisigOptimism is ApproveTokensResolver {
    string constant public name = "ApproveTokens-v1";
}