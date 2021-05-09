pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { InstaFlashV2Interface } from "./interfaces.sol";

contract Variables {

    /**
    * @dev Instapool / Receiver contract proxy
    */
    InstaFlashV2Interface public constant instaPool = InstaFlashV2Interface(0x691d4172331a11912c6D0e6D1A002E3d7CED6a66);
}