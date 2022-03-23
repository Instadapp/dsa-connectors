//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { InstaFlashV2Interface } from "./interfaces.sol";

contract Variables {

    /**
    * @dev Instapool contract proxy
    */
    InstaFlashV2Interface public constant instaPool = InstaFlashV2Interface(0x276B88D057b368179480CB707366d497DfC79726);

}