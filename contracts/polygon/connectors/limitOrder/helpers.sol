pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

import { Basic, TokenInterface } from "../../common/basic.sol";
import "./interface.sol";

contract Helpers is Basic {

    IUniLimitOrder public constant limitCon_ = IUniLimitOrder(0x94F401fAD3ebb89fB7380f5fF6E875A88E6Af916);

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount;
        bool tokenDirectn;
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

        if(params_.tokenDirectn){
            amountSend_ = params_.amount == type(uint128).max ? getTokenBal(TokenInterface(params_.token0)) : params_.amount;
            convertMaticToWmatic(params_.token0 == maticAddr, token0_, amountSend_);
            approve(token0_, address(limitCon_), amountSend_);
        } else {
            amountSend_ = params_.amount == type(uint128).max ? getTokenBal(TokenInterface(params_.token1)) : params_.amount;
            convertMaticToWmatic(params_.token1 == maticAddr, token1_, amountSend_);
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
                params_.tokenDirectn
            );

        (tokenId_, liquidity_, mintAmount_) = limitCon_.createPosition(parameter);

    }
}
