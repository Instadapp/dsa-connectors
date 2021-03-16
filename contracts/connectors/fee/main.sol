pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";

abstract contract FeeResolver is DSMath, Basic {
    /**
     * @dev Calculate fee
     */
    function calculateFee(
        uint amount,
        uint fee,
        uint getId,
        uint setId,
        uint setIdFee
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amount);

        uint feeAmt = wmul(_amt, fee);

        uint totalAmt = add(_amt, feeAmt);

        setUint(setId, totalAmt);
        setUint(setIdFee, feeAmt);
    }
}

contract ConnectV2Fee is FeeResolver {
    string public constant name = "Fee-v1";
}
