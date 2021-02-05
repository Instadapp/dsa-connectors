pragma solidity ^0.6.0;

import { Stores } from "../../common/stores.sol";

contract Events is Stores {
    event LogClaimedComp(uint256 compAmt, uint256 setId);
    event LogDelegate(address delegatee);
}
