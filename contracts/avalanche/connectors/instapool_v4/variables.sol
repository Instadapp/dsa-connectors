pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { InstaFlashV4Interface } from "./interfaces.sol";

contract Variables {

    /**
    * @dev Instapool contract proxy
    */
    InstaFlashV4Interface public constant instaPool = InstaFlashV4Interface(address(0)); // TODO: update address

}