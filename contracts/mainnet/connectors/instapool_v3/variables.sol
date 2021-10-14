pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { InstaFlashV2Interface } from "./interfaces.sol";

contract Variables {

    /**
    * @dev Instapool contract proxy
    */
    InstaFlashV2Interface public immutable instaPool;

    constructor(address _instaPool) {
        instaPool = InstaFlashV2Interface(_instaPool);
    }

}