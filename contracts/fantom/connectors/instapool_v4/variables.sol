//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { InstaFlashV4Interface } from "./interfaces.sol";

contract Variables {

    /**
    * @dev Instapool contract proxy
    */
    InstaFlashV4Interface public constant instaPool = InstaFlashV4Interface(0x22ed23Cc6EFf065AfDb7D5fF0CBf6886fd19aee1);

}