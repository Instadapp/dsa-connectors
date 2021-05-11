pragma solidity ^0.7.0;

/**
 * @title Fee.
 * @dev Calculate Fee.
 */

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";

abstract contract FeeResolver is DSMath, Basic {
    /**
     * @dev Calculate fee
     * @notice Calculates fee on a given amount
     * @param amount token amount to caculate fee.
     * @param fee fee percentage. Eg: 1% => 1e17, 100% => 1e18.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set total amount at this ID in `InstaMemory` Contract.
     * @param setIdFee Set only fee amount at this ID in `InstaMemory` Contract.
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

    /**
     * @dev Calculate amount minus fee
     * @notice Calculates amount minus fee 
     * @param amount token amount to caculate fee.
     * @param fee fee percentage. Eg: 1% => 1e17, 100% => 1e18.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setIdAmtMinusFee Set amount minus fee amount at this ID in `InstaMemory` Contract.
     * @param setIdFee Set only fee amount at this ID in `InstaMemory` Contract.
     */
    function calculateAmtMinusFee(
        uint amount,
        uint fee,
        uint getId,
        uint setIdAmtMinusFee,
        uint setIdFee
    ) external payable {
        uint _amt = getUint(getId, amount);

        uint feeAmt = wmul(_amt, fee);
        uint amountMinusFee = sub(_amt, feeAmt);

        setUint(setIdAmtMinusFee, amountMinusFee);
        setUint(setIdFee, feeAmt);
    }
}

contract ConnectV2Fee is FeeResolver {
    string public constant name = "Fee-v1";
}
