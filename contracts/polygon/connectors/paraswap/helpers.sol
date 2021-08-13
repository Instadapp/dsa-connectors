pragma solidity ^0.7.0;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { AugustusSwapperInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {

    struct SwapData {
        TokenInterface sellToken;
        TokenInterface buyToken;
        uint256 _sellAmt;
        uint256 _buyAmt;
        uint256 unitAmt;
        bytes callData;
    }

    address internal constant paraswap = 0x90249ed4d69D70E709fFCd8beE2c5A566f65dADE;

    function _swapHelper(SwapData memory swapData, uint256 wmaticAmt) internal returns (uint256 buyAmt) {
        TokenInterface buyToken = swapData.buyToken;
        (uint256 _buyDec, uint256 _sellDec) = getTokensDec(buyToken, swapData.sellToken);
        uint256 _sellAmt18 = convertTo18(_sellDec, swapData._sellAmt);
        uint256 _slippageAmt = convert18ToDec(_buyDec, wmul(swapData.unitAmt, _sellAmt18));

        uint256 initalBal = getTokenBal(buyToken);

        (bool success, ) = paraswap.call{value: wmaticAmt}(swapData.callData);
        if (!success) revert("paraswap-failed");

        uint256 finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    function _swap(SwapData memory swapData, uint256 setId) internal returns (SwapData memory) {
        TokenInterface _sellAddr = swapData.sellToken;

        uint256 maticAmt;

        if (address(_sellAddr) == maticAddr) {
            maticAmt = swapData._sellAmt;
        } else {
            address tokenProxy = AugustusSwapperInterface(paraswap).getTokenTransferProxy();
            approve(TokenInterface(_sellAddr), tokenProxy, swapData._sellAmt);
        }

        swapData._buyAmt = _swapHelper(swapData, maticAmt);

        setUint(setId, swapData._buyAmt);

        return swapData;
    }
}