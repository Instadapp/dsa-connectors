//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {ZeroExData} from "./interface.sol";

contract Helpers is DSMath, Basic {
    /**
     * @dev 0x Address
     */
    address internal constant zeroExAddr =
        0xDEF189DeAEF76E379df891899eb5A00a94cBC250;

    function _swapHelper(ZeroExData memory zeroExData, uint256 ftmAmt)
        internal
        returns (uint256 buyAmt)
    {
        TokenInterface buyToken = zeroExData.buyToken;
        (uint256 _buyDec, uint256 _sellDec) = getTokensDec(
            buyToken,
            zeroExData.sellToken
        );
        uint256 _sellAmt18 = convertTo18(_sellDec, zeroExData._sellAmt);
        uint256 _slippageAmt = convert18ToDec(
            _buyDec,
            wmul(zeroExData.unitAmt, _sellAmt18)
        );

        uint256 initalBal = getTokenBal(buyToken);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = zeroExAddr.call{value: ftmAmt}(zeroExData.callData);
        if (!success) revert("0x-swap-failed");

        uint256 finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    function _swap(ZeroExData memory zeroExData, uint256 setId)
        internal
        returns (ZeroExData memory)
    {
        TokenInterface _sellAddr = zeroExData.sellToken;

        uint256 ftmAmt;
        if (address(_sellAddr) == ftmAddr) {
            ftmAmt = zeroExData._sellAmt;
        } else {
            approve(
                TokenInterface(_sellAddr),
                zeroExAddr,
                zeroExData._sellAmt
            );
        }

        zeroExData._buyAmt = _swapHelper(zeroExData, ftmAmt);
        setUint(setId, zeroExData._buyAmt);

        return zeroExData;
    }
}
