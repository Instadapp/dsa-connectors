pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { InstaFlashV2Interface } from "./interfaces.sol";

contract Variables {

    /**
    * @dev Instapool contract proxy
    */
    InstaFlashV2Interface public constant instaPool = InstaFlashV2Interface(0x9686CE6Ad5C3f7b212CAF401b928c4bB3422E7Ba);

}