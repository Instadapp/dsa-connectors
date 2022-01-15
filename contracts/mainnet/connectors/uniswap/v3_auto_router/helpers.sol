pragma solidity ^0.7.0;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import {SwapData} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev UniswapV3 Swap Router Address
     */
   address internal constant V3_SWAP_ROUTER_ADDRESS = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;


     /**
     * @dev UniswapV3 swapHelper
     * @param swapData - Struct defined in interfaces.sol
     */
    function _swapHelper(
        SwapData memory swapData
    ) internal returns (uint buyAmt) {
        
        TokenInterface sellToken = address(swapData.sellToken) == ethAddr ? TokenInterface(wethAddr) : swapData.sellToken;
        TokenInterface buyToken = address(swapData.buyToken) == ethAddr ?  TokenInterface(wethAddr) : swapData.buyToken;
         
         bool isEth = address(swapData.sellToken) == ethAddr;
        convertEthToWeth(isEth, sellToken, swapData._sellAmt);

        approve(TokenInterface(sellToken), V3_SWAP_ROUTER_ADDRESS, swapData._sellAmt);
    
        (uint _buyDec, uint _sellDec) = getTokensDec(buyToken, swapData.sellToken);
        uint _sellAmt18 = convertTo18(_sellDec, swapData._sellAmt);
        uint _slippageAmt = convert18ToDec(_buyDec, wmul(swapData.unitAmt, _sellAmt18));

        uint initalBal = getTokenBal(buyToken);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = V3_SWAP_ROUTER_ADDRESS.call(swapData.callData);
        if (!success) revert("uniswapV3-swap-failed");

        uint finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);
        require(_slippageAmt <= buyAmt, "Too much slippage");

       isEth = address(buyToken) == ethAddr;
       convertWethToEth(isEth,buyToken,buyAmt);
    }

     /**
     * @dev Gets the swapping data from auto router sdk
     * @param swapData Struct with multiple swap data defined in interfaces.sol 
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
     */
    function _Swap(
        SwapData memory swapData,
        uint setId
    ) internal returns (SwapData memory) {
        
        swapData._buyAmt = _SwapHelper(swapData);
        setUint(setId, swapData._buyAmt);

        return swapData;

    }

}