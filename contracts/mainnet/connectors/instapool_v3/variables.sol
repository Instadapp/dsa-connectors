pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { InstaFlashV2Interface } from "./interfaces.sol";

contract Variables {

    /**
    * @dev Instapool contract proxy
    */
    InstaFlashV2Interface public constant instaPool = InstaFlashV2Interface(0xF77A5935f35aDD4C2f524788805293EF86B87560);

}