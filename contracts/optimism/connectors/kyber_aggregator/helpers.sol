//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {TokenInterface} from "../../common/interfaces.sol";

abstract contract Helpers is DSMath, Basic {
    struct SwapData {
        TokenInterface sellToken;
        TokenInterface buyToken;
        uint256 _sellAmt;
        uint256 _buyAmt;
        uint256 unitAmt;
        bytes callData;
    }

    address internal constant kyberswap =
        0x6131B5fae19EA4f9D964eAc0408E4408b66337b5;

    function _swapHelper(SwapData memory swapData, uint256 ethAmt)
        internal
        returns (uint256 buyAmt)
    {
        TokenInterface buyToken = swapData.buyToken;
        (uint256 _buyDec, uint256 _sellDec) = getTokensDec(
            buyToken,
            swapData.sellToken
        );
        uint256 _sellAmt18 = convertTo18(_sellDec, swapData._sellAmt);
        uint256 _slippageAmt = convert18ToDec(
            _buyDec,
            wmul(swapData.unitAmt, _sellAmt18)
        );

        uint256 initalBal = getTokenBal(buyToken);
        (bool success, ) = kyberswap.call{value: ethAmt}(swapData.callData);
        if (!success) revert("kyberswap-failed");

        uint256 finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    function _swap(SwapData memory swapData, uint256 setId)
        internal
        returns (SwapData memory)
    {
        TokenInterface _sellAddr = swapData.sellToken;

        uint256 ethAmt;

        if (address(_sellAddr) == ethAddr) {
            ethAmt = swapData._sellAmt;
        } else {
            approve(TokenInterface(_sellAddr), kyberswap, swapData._sellAmt);
        }
        swapData._buyAmt = _swapHelper(swapData, ethAmt);

        setUint(setId, swapData._buyAmt);

        return swapData;
    }
}
