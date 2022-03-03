pragma solidity ^0.8.1;
// SPDX-License-Identifier: MIT

import { Basic } from "../../common/basic.sol";
import "./interface.sol";

contract Helpers is Basic {

    IUniLimitOrder public constant limitCon_ = IUniLimitOrder(0xfC428E6535dC5Fee30fb57cFc93EBB1D92fdCf6e);

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount;
        bool token0to1;
    }

    /**
     * @dev Mint function which interact with Uniswap v3
     */
    function _createPosition (MintParams memory params_)
        internal
        returns (
            uint256 tokenId_,
            uint128 liquidity_,
            uint256 mintAmount_
        )
    {
        uint256 amountSend_;

        (TokenInterface token0_, TokenInterface token1_) = changeMaticAddress(
            params_.token0,
            params_.token1
        );

        if(params_.token0to1){
            amountSend_ = params_.amount == type(uint128).max ? getTokenBal(TokenInterface(params_.token0)) : params_.amount;
            convertMaticToWmatic(address(token0_) == wmaticAddr, token0_, amountSend_);
            approve(token0_, address(limitCon_), amountSend_);
        } else {
            amountSend_ = params_.amount == type(uint128).max ? getTokenBal(TokenInterface(params_.token1)) : params_.amount;
            convertMaticToWmatic(address(token1_) == wmaticAddr, token1_, amountSend_);
            approve(token1_, address(limitCon_), amountSend_);
        }

        IUniLimitOrder.MintParams memory parameter = 
            IUniLimitOrder.MintParams(
                address(token0_),
                address(token1_),
                params_.fee,
                params_.tickLower,
                params_.tickUpper,
                amountSend_,
                params_.token0to1
            );

        (tokenId_, liquidity_, mintAmount_) = limitCon_.createPosition(parameter);

    }
}