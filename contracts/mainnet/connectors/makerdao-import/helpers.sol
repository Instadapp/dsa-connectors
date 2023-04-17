// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { ManagerLike, VatLike, IAvoFactory, IAvoCreditManagerAddress } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    ManagerLike internal constant managerContract = ManagerLike(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
    IAvoFactory internal constant avoFactory = IAvoFactory(0x3AdAE9699029AB2953F607AE1f62372681D35978);
    IAvoCreditManagerAddress internal constant avoCreditManager = IAvoCreditManagerAddress(0xE4C9751D5CBCde942165871Ca2089172307F9971);

    function getVaultData(uint vault) internal view returns (bytes32 ilk, address urn) {
        ilk = managerContract.ilks(vault);
        urn = managerContract.urns(vault);
    }

    function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
        require(bytes(str).length != 0, "string-empty");
        assembly {
            result := mload(add(str, 32))
        }
    }

    function getVault(uint vault) internal view returns (uint _vault) {
        if (vault == 0) {
            require(managerContract.count(address(this)) > 0, "no-vault-opened");
            _vault = managerContract.last(address(this));
        } else {
            _vault = vault;
        }
    }
}