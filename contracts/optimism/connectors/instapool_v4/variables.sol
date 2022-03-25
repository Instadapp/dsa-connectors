pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { InstaFlashV4Interface } from "./interfaces.sol";

contract Variables {

    /**
    * @dev Instapool contract proxy
    */
    InstaFlashV4Interface public constant instaPool = InstaFlashV4Interface(0x84E6b05A089d5677A702cF61dc14335b4bE5b282);

}