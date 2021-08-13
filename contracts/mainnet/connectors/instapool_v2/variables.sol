pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { InstaFlashV2Interface } from "./interfaces.sol";

contract Variables {

    /**
    * @dev Instapool contract proxy
    */
    InstaFlashV2Interface public constant instaPool = InstaFlashV2Interface(0x2a1739D7F07d40e76852Ca8f0D82275Aa087992F);
}