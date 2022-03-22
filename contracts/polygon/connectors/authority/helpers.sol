//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { ListInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    ListInterface internal constant listContract = ListInterface(0x839c2D3aDe63DF5b0b8F3E57D5e145057Ab41556);

    function checkAuthCount() internal view returns (uint count) {
        uint64 accountId = listContract.accountID(address(this));
        count = listContract.accountLink(accountId).count;
    }
}
