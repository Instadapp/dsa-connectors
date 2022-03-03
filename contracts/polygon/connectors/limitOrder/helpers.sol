pragma solidity ^0.8.1;
// SPDX-License-Identifier: MIT

import { Basic } from "../../common/basic.sol";
import "./interface.sol";

contract Helpers is Basic {

    UniLimitOrder limitCon_ = UniLimitOrder(0xfC428E6535dC5Fee30fb57cFc93EBB1D92fdCf6e);

    function sortTokenAddress(address _token0, address _token1)
        internal
        pure
        returns (address token0, address token1)
    {
        if (_token0 > _token1) {
            (token0, token1) = (_token1, _token0);
        } else {
            (token0, token1) = (_token0, _token1);
        }
    }

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
            approve(TokenInterface(token0_), address(limitCon_), amountSend_);
        } else {
            amountSend_ = params_.amount == type(uint128).max ? getTokenBal(TokenInterface(params_.token1)) : params_.amount;
            convertMaticToWmatic(address(token1_) == wmaticAddr, token1_, amountSend_);
            approve(TokenInterface(token1_), address(limitCon_), amountSend_);
        }

        {
            (address token0, ) = sortTokenAddress(
                address(token0_),
                address(token1_)
            );

            if (token0 != address(token0_)) {
                (token0_, token1_) = (token1_, token0_);
            }
        }

        UniLimitOrder.MintParams memory parameter = 
            UniLimitOrder.MintParams(
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