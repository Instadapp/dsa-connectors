// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface, AccountInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

contract MakerTransferResolver is Helpers, Events {
    function transferToAvo(uint256 vaultId) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _vault = getVault(vaultId);
        (bytes32 ilk,) = getVaultData(_vault);

        require(managerContract.owns(_vault) == address(this), "not-owner");

        address avoAddress = avoFactory.computeAddress(msg.sender);
        managerContract.give(_vault, avoAddress);

        avoCreditManager.dsaMakerImport(_vault, avoAddress, msg.sender);

        _eventName = "LogTransferToAvo(uint256,bytes32,address)";
        _eventParam = abi.encode(_vault, ilk, avoAddress);
    }
}

contract ConnectV2AvoMakerImport is MakerTransferResolver {
    string public constant name = "Avocado-Maker-Import-v1.0";
}