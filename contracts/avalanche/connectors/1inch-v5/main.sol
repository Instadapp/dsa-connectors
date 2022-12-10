//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title 1InchV5.
 * @dev On-chain DEX Aggregator.
 */

// import files from common directory
import { TokenInterface , MemoryInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { OneInchInterace, OneInchData } from "./interface.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract OneInchResolver is Helpers, Events {
    /**
     * @dev 1inch API swap handler
     * @param oneInchData - contains data returned from 1inch API. Struct defined in interfaces.sol
     * @param avaxAmt - Avax to swap for .value()
     */
    function oneInchSwap(
        OneInchData memory oneInchData,
        uint avaxAmt
    ) internal returns (uint buyAmt) {
        TokenInterface buyToken = oneInchData.buyToken;
        (uint _buyDec, uint _sellDec) = getTokensDec(buyToken, oneInchData.sellToken);
        uint _sellAmt18 = convertTo18(_sellDec, oneInchData._sellAmt);
        uint _slippageAmt = convert18ToDec(_buyDec, wmul(oneInchData.unitAmt, _sellAmt18));

        uint initalBal = getTokenBal(buyToken);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = oneInchAddr.call{value: avaxAmt}(oneInchData.callData);
        if (!success) revert("1Inch-swap-failed");

        uint finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

}

abstract contract OneInchResolverHelpers is OneInchResolver {

    /**
     * @dev Gets the swapping data from 1inch's API.
     * @param oneInchData Struct with multiple swap data defined in interfaces.sol 
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
     */
    function _sell(
        OneInchData memory oneInchData,
        uint setId
    ) internal returns (OneInchData memory) {
        TokenInterface _sellAddr = oneInchData.sellToken;

        uint avaxAmt;
        if (address(_sellAddr) == avaxAddr) {
            avaxAmt = oneInchData._sellAmt;
        } else {
            approve(TokenInterface(_sellAddr), oneInchAddr, oneInchData._sellAmt);
        }

        oneInchData._buyAmt = oneInchSwap(oneInchData, avaxAmt);
        setUint(setId, oneInchData._buyAmt);

        return oneInchData;

    }
}

abstract contract OneInch is OneInchResolverHelpers {
    /**
     * @dev Sell Avax/ERC20_Token using 1Inch.
     * @notice Swap tokens from exchanges like kyber, 0x etc, with calculation done off-chain.
     * @param buyAddr The address of the token to buy.(For Avax: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr The address of the token to sell.(For Avax: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt The amount of the token to sell.
     * @param unitAmt The amount of buyAmt/sellAmt with slippage.
     * @param callData Data from 1inch API.
     * @param setId ID stores the amount of token brought.
    */
    function sell(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        bytes calldata callData,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        OneInchData memory oneInchData = OneInchData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            unitAmt: unitAmt,
            callData: callData,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        oneInchData = _sell(oneInchData, setId);

        _eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, oneInchData._buyAmt, oneInchData._sellAmt, 0, setId);
    }
}

contract ConnectV2OneInchV5Avalanche is OneInch {
    string public name = "1Inch-v5";
}
